pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AgreementFactory is Ownable {
    uint256 public loanNumber;
    uint256 public rate;
    uint256 public agentCommission;
    uint256 public loanAmount;
    uint256 public loanDuration;
    address public agentAddress;
    address public userAddress;
    uint256 public daysSinceCreation;
    uint256 public daysOverdue;
    bool public loanRepaid;
    address public ottleyWallet;
    bool public ottleyVerified;
    bool public agentVerified;
    bool public loanActive;
    uint256 public lastUpdateTimestamp; 

    struct LoanAgreement {
        uint256 rate;
        uint256 agentCommission;
        uint256 loanAmount;
        uint256 loanDuration;
        address agentAddress;
        address userAddress;
        //bool agentWhitelist; -> implemented at a later date
        //bool userWhitelist; -> implemented at a later date
        uint256 daysSinceCreation;
        uint256 daysOverdue;
        bool loanRepaid;
        bool ottleyVerified;
        bool agentVerified;
        bool loanActive;
        uint256 lastUpdateTimestamp;
    }

    //mapping loanNumber to LoanAgreement struct
    mapping(uint256 => LoanAgreement) public _LoanNumberToLoanAgreement;  

    event loanCreated(uint256 LoanNumber, uint256 Rate, uint256 LoanAmount, uint256 LoanDuration, address AgentAddress, address UserAddress);
    event loanDeprecated(uint256 LoanNumber, uint256 LoanAmount, uint256 LoanDuration, uint256 DaysSinceCreation, uint256 DaysOverdue, bool LoanRepaid);
    event loanApproved(uint256 LoanNumber, uint256 Rate, uint256 LoanAmount, uint256 LoanDuration, address AgentAddress, address UserAddress, 
            bool OttleyVerified, bool AgentVerified);
    event loanRebased(uint256 LoanNumber, uint256 newLoanValue, uint256 updateBlockTime);

    //will also need to add in {address agentWhitelist, address userWhitelist} into the constructor
    constructor(address OttleyWallet) public {
        loanNumber = 1;
        ottleyWallet = OttleyWallet;
    }
    
    /** @notice function call used for creating loan agreements
        @param Rate interest rate involved in the loanAgreement
        @param LoanAmount amount issued in the loan
        @param LoanDuration duration of the created loan*/
    function createLoanAgreement(uint256 LoanAmount, uint256 LoanDuration, uint256 Rate, address AgentAddress) public returns (uint256) {
        //require agent address to be on agentWhitelist
        //require user address to be on userWhitelist
        uint256 newLoanNumber = loanNumber;
        LoanAgreement memory loanAgreement;
        loanAgreement = LoanAgreement(Rate, 0, LoanAmount, LoanDuration, AgentAddress, msg.sender, 0, 0, false, false, false, false, block.timestamp());
        _LoanNumberToLoanAgreement[newLoanNumber] = loanAgreement;
        loanNumber++;
        emit loanCreated(NewLoanNumber, Rate, LoanAmount, LoanDuration, AgentAddress, msg.sender);
        return newLoanNumber;
    }

    /** @notice function used to execute an existing loan agreement
        @param LoanNumber the loan number for the loan to be executed */
    function ExecuteLoanAgreement(uint256 LoanNumber) public payable returns (bool) {
        require(_LoanNumberToLoanAgreement[LoanNumber].ottleyVerified = true, "ERROR: Loan not verified by Ottley Wallet");
        require(_LoanNumberToLoanAgreement[LoanNumber].agentVerified = true, "ERROR: Loan not verified by agent");
        _LoanNumberToLoanAgreement[LoaNumber].loanActive = true;

        //fund transfer executes here
        bool valueTransfer = _LoanNumberToLoanAgreement[LoanNumber].userAddress.send(_LoanNumberToLoanAgreement[LoanNumber].loanValue);
        require(valueTransfer == true, "ERROR: Could not execute value transfer");

        emit loanApproved(LoanNumber, _LoanNumberToLoanAgreement[LoanNumber].rate, _LoanNumberToLoanAgreement[LoanNumber].loanAmount, 
        _LoanNumberToLoanAgreement[LoanNumber].loanDuration, _LoanNumberToLoanAgreement[LoanNumber].agentAddress, 
        _LoanNumberToLoanAgreement[LoanNumber].userAddress, _LoanNumberToLoanAgreement[LoanNumber].ottleyVerified, 
        _LoanNumberToLoanAgreement[LoanNumber].agentVerified);
        return _LoanNumberToLoanAgreement[LoanNumber].loanActive;
    }

    /** @notice function call for the Ottley wallet to verify the loan agreement
        @param LoanNumber the loan number that the verification is for
        @dev ideally we will be able to remove this function and have this verification performed through ethereum signing*/
    function OttleyVerify(uint256 LoanNumber) public returns (bool) {
        require(msg.sender == ottleyWallet, "ERROR: OttleyVerify only callable by Ottley Capital Wallet");
        _LoanNumberToLoanAgreement[LoanNumber].ottleyVerified = true;
        return _LoanNumberToLoanAgreement[LoanNumber].ottleyVerified;
    }

    /** @notice function call for the Agent to verify the loan agreement
        @param LoanNumber the loan number that the verification is for
        @dev ideally we will be able to remove this function and have this verification performed through ethereum signing */
    function AgentVerify(uint256 LoanNumber) public returns (bool){
        address AgentWallet = _LoanNumberToLoanAgreement[LoanNumber].agentWallet;
        require(msg.sender == AgentWallet, "ERROR: AgentVerify only callable by designated Agent wallet");
        _LoanNumberToLoanAgreement[LoanNumber].agentVerified = true;
        return _LoanNumberToLoanAgreement[LoanNumber].agentVerified;
    }

    /** @notice function call used to rebase all existing loans - to be called by the keeper contract*/
    function rebaseAll() public{
        for (uint256 i = 1; i<=LoanNumber; i++){
            if(_LoanNumberToLoanAgreement[i].loanActive == true) {
                rebase(i);
            }
        }
    }

    /** @notice function call used to rebase a specific loan
        @param LoanNumber the LoanNumber of the loan to be rebased*/
    }
    function rebase(uint256 LoanNumber) public returns (uint256) {
        require(_LoanNumberToLoanAgreement[LoanNumber].loanActive == false, "ERROR: Loan inactive");
        if(_LoanNumberToLoanAgreement[LoanNumber].loanRepaid == true) {
            deprecateLoan(LoanNumber);
        }
        else if(_LoanNumberToLoanAgreement[LoanNumber].loanRepaid == false) {
            uint256 currenttime = block.timestamp();
            //Find blocktime for last update + 1 day(86400 seconds)
            uint256 lastUpdateCooldown = _LoanNumberToLoanAgreement[LoanNumber].lastUpdateTimestamp + 86400; 
            require(currenttime > lastUpdateCooldown, "ERROR: function call on cooldown");
            uint256 compoundEvents = (currenttime - lastUpdateCooldown)/86400;
            uint256 loanValue = _LoanNumberToLoanAgreement[LoanNumber].loanAmount;
            uint256 loanRate = _LoanNumberToLoanAgreement[LoanNumber].rate;
            for (uint256 i = 1; i <= compoundEvents; i++){
                loanValue = loanValue + loanValue*loanRate;
            }
            _LoanNumberToLoanAgreement[LoanNumber].loanAmount = loanValue;
            _LoanNumberToLoanAgreement[LoanNumber].lastUpdateTimeStamp = currenttime;
            emit loanRebased(LoanNumber, _LoanNumberToLoanAgreement[LoanNumber].loanAmount, currenttime);
        }
    return loanNumber;
    }

    /** @notice function call used to 'deprecate' a loan - called when a loan has been fully repaid
        @param LoanNumber the loanNumber for the loan to be deprecated */
    function deprecateLoan(uint256 LoanNumber) public returns (uint256) {
        require(_LoanNumberToLoanAgreement[LoanNumber].loanActive == true, "ERROR: Loan already inactive");
        require(_LoanNumberToLoanAgreement[LoanNumber].loanRepaid == true, "ERROR: Loan has not been repaid");
        
        //route fee to agent account

        _LoanNumberToLoanAgreement[LoanNumber].loanActive = false;

        emit loanDeprecated(LoanNumber, _LoanNumberToLoanAgreement[LoanNumber].LoanAmount, _LoanNumberToLoanAgreement[LoanNumber].LoanDuration, 
        _LoanNumberToLoanAgreement[LoanNumber].DaysSinceCreation, _LoanNumberToLoanAgreement[LoanNumber].DaysOverdue, 
        _LoanNumberToLoanAgreement[LoanNumber].LoanRepaid, _LoanNumberToLoanAgreement[LoanNumber].loanActive);

        return LoanNumber;
    }

} 