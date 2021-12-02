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
    }

    //mapping loanNumber to LoanAgreement struct
    mapping(uint256 => LoanAgreement) public _LoanNumberToLoanAgreement;  

    event loanCreated(uint256 Rate, uint256 LoanAmount, uint256 LoanDuration, address AgentAddress, address UserAddress);
    event loanDeprecated(uint256 Rate, uint256 LoanAmount, uint256 LoanDuration, address AgentAddress, address UserAddress, uint256 DaysSinceCreation, 
            uint256 DaysOverdue, bool LoanRepaid);

    constructor(address OttleyWallet) public {
        loanNumber = 1;
        ottleyWallet = OttleyWallet;
    }
    
    /** @notice function call used for creating loan agreements
        @param Rate interest rate involved in the loanAgreement
        @param LoanAmount amount issued in the loan
        @param LoanDuration duration of the created loan*/
    function createLoanAgreement(uint256 LoanAmount, uint256 LoanDuration, uint256 Rate, address AgentAddress) public returns (uint256) {
        uint256 newLoanNumber = loanNumber;
        LoanAgreement memory loanAgreement;
        loanAgreement = LoanAgreement(Rate, 0, LoanAmount, LoanDuration, AgentAddress, msg.sender, 0, 0, false);
        _LoanNumberToLoanAgreement[newLoanNumber] = loanAgreement;
        loanNumber++;
        //agentWallet must sign
        //ottleyWallet must sign
        emit loanCreated(Rate, LoanAmount, LoanDuration, AgentAddress, msg.sender);
        return newLoanNumber;
    }

    /** @notice function call used to rebase all existing loans - to be called by the timekeep oracle
        @dev this function will be called by a time oracle on 24 hour blocks 
        @dev function cooldown set to 23.59 hours (if possible)*/
    function rebaseAll() public{

    }
    /** @notice function call used to rebase a specific loan
        @param LoanNumber the LoanNumber of the loan to be rebased*/
    }
    function rebase(uint256 LoanNumber) public {
        //require(!loanNumberToLoanrepaid[LoanNumber])
    }
    /** @notice function call used to 'deprecate' a loan - called when a loan has been fully repaid
        @param LoanNumber the loanNumber for the loan to be deprecated */
    function deprecateLoan(uint256 LoanNumber) public{

    }

}