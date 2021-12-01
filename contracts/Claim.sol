//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './interfaces/IVesting.sol';

//Contract to claim inital 100 tokens
contract Claim {
    IERC20 public _token;
    IVesting public _vesting;  
    
    mapping(address => bool) public claimed;

    constructor(address token, address vesting) public {
        _token = IERC20(token);
        _vesting = IVesting(vesting);
    }

    function claimTokens() public {
        require(!claimed[msg.sender], "Initial Claim: No double claiming");
        
        //Forked logic from Tracer contract
        //0.01% of 1 billion = 100000
        //1 Token sent immediately
        //99999 vesting over 3 years with a 6 month cliff
        uint256 singleToken = 1 * 10 ** 18;
        uint256 vestingTokens = 99999 * 10 ** 18;

        _token.safeTransfer(msg.sender, singleToken);
        _token.safeTransfer(address(_vesting), vestingTokens);

        _vesting.setVestingSchedule(msg.sender, vestingTokens, true, 26, 156);

        claimed[msg.sender] = true;
    }
}




