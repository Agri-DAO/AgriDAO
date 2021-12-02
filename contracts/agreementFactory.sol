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
        bool ottleyVerified;
        bool agentVerified;
        bool loanActive;
    }

    //mapping loanNumber to LoanAgreement struct
    mapping(uint256 => LoanAgreement) public _LoanNumberToLoanAgreement;  

    event loanCreated(uint256 LoanNumber, uint256 Rate, uint256 LoanAmount, uint256 LoanDuration, address AgentAddress, address UserAddress);
    event loanDeprecated(uint256 Rate, uint256 LoanAmount, uint256 LoanDuration, address AgentAddress, address UserAddress, uint256 DaysSinceCreation, 
            uint256 DaysOverdue, bool LoanRepaid);
    event loanApproved(uint256 LoanNumber, uint256 Rate, uint256 LoanAmount, uint256 LoanDuration, address AgentAddress, address UserAddress, 
            bool OttleyVerified, bool AgentVerified);

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
        loanAgreement = LoanAgreement(Rate, 0, LoanAmount, LoanDuration, AgentAddress, msg.sender, 0, 0, false, false, false, false);
        _LoanNumberToLoanAgreement[newLoanNumber] = loanAgreement;
        loanNumber++;
        emit loanCreated(NewLoanNumber, Rate, LoanAmount, LoanDuration, AgentAddress, msg.sender);
        return newLoanNumber;
    }
    
    /** @notice function used to execute an existing loan agreement
        @param LoanNumber the loan number for the loan to be executed */
    function ExecuteLoanAgreement(uint256 LoanNumber) public returns (bool) {
        require(_LoanNumberToLoanAgreement[LoanNumber].ottleyVerified = true, "ERROR: Loan not verified by Ottley Wallet");
        require(_LoanNumberToLoanAgreement[LoanNumber].agentVerified = true, "ERROR: Loan not verified by agent");
        _LoanNumberToLoanAgreement[LoaNumber].loanActive = true;

        //fund transfer executes here

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

    /** @notice function call used to rebase all existing loans - to be called by the timekeep oracle
        @dev this function will be called by a time oracle on 24 hour blocks 
        @dev function cooldown set to 23.59 hours (if possible)*/
    function rebaseAll() public{

    }

    /** @notice function call used to rebase a specific loan
        @param LoanNumber the LoanNumber of the loan to be rebased*/
    }
    function rebase(uint256 LoanNumber) public {

    }

    /** @notice function call used to 'deprecate' a loan - called when a loan has been fully repaid
        @param LoanNumber the loanNumber for the loan to be deprecated */
    function deprecateLoan(uint256 LoanNumber) public{

    }

}