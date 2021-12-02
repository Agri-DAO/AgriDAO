//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//relevant includes IVesting.sol etc...
import './interfaces/IVesting.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Vesting is  Ownable, IVesting {
    
    struct Schedule {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 endTime;
        bool isFixed;
        bool cliffClaimed;
    }

    mapping(address => mapping(uint => Schedule)) public schedules;
    mapping(address => uint) public numberOfSchedules;

    uint256 valueLocked;
    IERC20 private DAOToken;

    event Claim(uint amount, address claimer);

    constructor(address _token) public {
        DAOToken = IERC20(_token);
    }

    function setVestingSchedule(
        address account,
        uint256 amount,
        bool isFixed,
        uint256 cliffWeeks,
        uint256 vestingWeeks
    ) public override onlyOwner {
        require(
            (DAOToken.balanceOf(address(this)) - valueLocked) >= amount, 
            "Vesting: not enough tokens in contract");
        require(vestingWeeks >= cliffWeeks, "Vesting: Cannot withdraw before cliff period");

        uint256 currentNumSchedules = numberOfSchedules[account];
        schedules[account][currentNumSchedules] = Schedule(
            amount,
            0,
            block.timestamp,
            block.timestamp + (cliffWeeks * 1 weeks),
            block.timestamp + (vestingWeeks * 1 weeks),
            isFixed,
            false
        );

        numberOfSchedules[account] = currentNumSchedules + 1;
        valueLocked = valueLocked + amount;

    }


    function claim(uint256 scheduleNumber) public override {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        require(
            schedule.cliffTime <= block.timestamp,
            "Vesting: cliffTime not reached" 
        );

        require(schedule.totalAmount > 0, "Vesting: No claimable tokens");

        uint amount = calcDistribution(schedule.totalAmount, block.timestamp, schedule.startTime, schedule.endTime);
        
        amount = amount > schedule.totalAmount ? schedule.totalAmount : amount;
        uint amountToTransfer = amount - schedule.claimedAmount;
        schedule.claimedAmount = amount;
        DAOToken.transfer(msg.sender, amountToTransfer);
        emit Claim(amount, msg.sender);
    }

    function cancelVesting(address account, uint256 scheduled) public override onlyOwner {
        Schedule storage schedule = schedules[account][scheduled];
        require(schedule.claimedAmount < schedule.totalAmount, "Vesting: Tokens fully claimed");
        require(!schedule.isFixed, "Vesting: Account is fixed");

        uint256 outstandingAmount = schedule.totalAmount - schedule.claimedAmount;

        schedule.totalAmount = 0;
        valueLocked = valueLocked - outstandingAmount;
    }
    
    function getVesting(address account, uint scheduleId) public override view returns (uint256, uint256) {
        Schedule memory schedule = schedules[account][scheduleId];        
        return (schedule.totalAmount, schedule.claimedAmount);
    }


    function calcDistribution(uint amount, uint currentTime, uint startTime, uint endTime)
        public
        override
        pure
        returns(uint256) {
            return amount * ((currentTime - startTime) / (endTime - startTime));
        }

        function withdraw (uint amount) public override onlyOwner {
            require(
                DAOToken.balanceOf(address(this)) - valueLocked >= amount,
                "Withdraw: not enough tokens left"
                
            );

            DAOToken.transfer(owner(), amount);
        }
}
