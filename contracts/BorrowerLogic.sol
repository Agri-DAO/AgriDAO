pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBorrowerLogic.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract BorrowerLogic is Context, AccessControl {
    uint256 public globalLoanNumber;
    uint256 public rate;
    uint256 public agentCommission;
    uint256 public loanAmount;
    uint256 public loanDuration;
    address public agentAddress;
    address public borrowerAddress;
    uint256 public creationTime;
    uint256 public maturityTime;
    bool public loanRepaid;
    address public delegateAddress;
    bool public delegateVerified;
    bool public loanActive;
    address public lenderContract;
    address public daoTreasury;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");
    bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");
    bytes32 public constant LENDER_ROLE = keccak256("LENDER_ROLE");


    struct LoanAgreement {
        uint256 rate;
        uint256 loanAmount;
        uint256 loanDuration;
        address borrowerAddress;
        uint256 creationTime;
        uint256 maturityTime;
        bool loanRepaid;
        bool delegateVerified;
        bool loanActive;
    }

    //mapping loanNumber to LoanAgreement struct
    mapping(uint256 => LoanAgreement) public _LoanNumberToLoanAgreement;

    event loanCreated(uint256 LoanNumber, uint256 Rate, uint256 LoanAmount, uint256 LoanDuration, address BorrowerAddress);
    event loanDeprecated(uint256 LoanNumber, uint256 LoanAmount, uint256 creationTime, uint256 maturityTime, uint256 DaysOverdue, bool LoanRepaid);
    event loanApproved(uint256 LoanNumber, uint256 Rate, uint256 LoanAmount, uint256 LoanDuration,address UserAddress,bool DelegateVerified);
    event loanOverdue(uint256 LoanNumber, uint256 ExpiryTimestamp, uint256 CurrentTimestamp);

    constructor(address DelegateAddress, address LenderContract, address DaoTreasury) public {
        globalLoanNumber = 1;
        delegateAddress = DelegateAddress;
        daoTreasury = DaoTreasury;
        lenderContract = LenderContract;
        _grantRole(OWNER_ROLE, _msgSender());
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(LENDER_ROLE, OWNER_ROLE);
        _setRoleAdmin(DELEGATE_ROLE, OWNER_ROLE);
        _setRoleAdmin(BORROWER_ROLE, OWNER_ROLE);

    }

    /** @notice function call used for creating loan agreements
        @param Rate interest rate involved in the loanAgreement
        @param LoanAmount amount issued in the loan
        @param LoanDuration duration of the created loan*/
    function createLoanAgreement(uint256 LoanAmount, uint256  LoanDuration, uint256 Rate) public onlyLender returns (uint256) {
        uint256 newLoanNumber = globalLoanNumber;
        LoanAgreement memory loanAgreement;
        uint256 currentTime = block.timestamp;
        uint256 expiryTimestamp = currentTime + (LoanDuration * 86400); //convert loan duration days to seconds
        loanAgreement = LoanAgreement(Rate, LoanAmount, LoanDuration, msg.sender, currentTime, expiryTimestamp, false, false, false);
        _LoanNumberToLoanAgreement[newLoanNumber] = loanAgreement;
        globalLoanNumber++;
        emit loanCreated(newLoanNumber, Rate, LoanAmount, LoanDuration, msg.sender);
        return newLoanNumber;
    }

    /** @notice function used to execute an existing loan agreement
        @param loanNumber the loan number for the loan to be executed
        @dev will have to update the fund transfer function to be exclusively payable in USDC*/
    function executeLoanAgreement(uint256 loanNumber) public payable returns (bool) {
        require(_LoanNumberToLoanAgreement[loanNumber].delegateVerified == true, "ERROR: Loan not verified by delegate wallet");
        _LoanNumberToLoanAgreement[loanNumber].loanActive = true;
        require(_LoanNumberToLoanAgreement[loanNumber].loanAmount == msg.value, "ERROR: msg.value not equal to loan amount");
        emit loanApproved(loanNumber, _LoanNumberToLoanAgreement[loanNumber].rate, _LoanNumberToLoanAgreement[loanNumber].loanAmount,
        _LoanNumberToLoanAgreement[loanNumber].loanDuration,_LoanNumberToLoanAgreement[loanNumber].borrowerAddress,
        _LoanNumberToLoanAgreement[loanNumber].delegateVerified);
        return _LoanNumberToLoanAgreement[loanNumber].loanActive;
    }



    /** @notice function call for the delegate wallet to verify the loan agreement
        @param loanNumber the loan number that the verification is for
        @dev ideally we will be able to remove this function and have this verification performed through ethereum signing*/
    function delegateVerify(uint256 loanNumber) public onlyDelegate returns (bool) {
        require(msg.sender == delegateAddress, "ERROR: DelegateVerify only callable by Delegate Wallet");
        _LoanNumberToLoanAgreement[loanNumber].delegateVerified = true;
        return _LoanNumberToLoanAgreement[loanNumber].delegateVerified;
    }

        /**@notice function call to check if a loan is overdue
    @param loanNumber the loan number that is checked if past maturity*/
    function checkOverdue(uint256 loanNumber) view public returns (bool) {
        if(_LoanNumberToLoanAgreement[loanNumber].maturityTime < block.timestamp
        && _LoanNumberToLoanAgreement[loanNumber].loanActive == false){
            return true;
        }
        else{
            return false;
        }
    }
        /**@notice function call to automatically route incoming funds
        @param loanNumber the loanNumber that the funds are being routed for
        @param loanAmount the final amount of the loan equal to the loanBase + interest
        @param loanBase the initial base amount of the loan */
    function routeFunds(uint256 loanNumber, uint256 loanAmount, uint256 loanBase) public onlyDelegate returns (bool){
        uint256 interestAmount = loanAmount - loanBase;
        uint256 interestAmountLenders = (interestAmount * 7)/(interestAmount * 10); // need to figure out a better way to multiply by decimal (this is * 0.7)
        uint256 interestAmountDAO = (interestAmount * 1)/(interestAmount * 10); // this is multiply by 0.1
        uint256 interestAmountDelegate = (interestAmount * 2)/(interestAmount * 10); // this is multiply by 0.2

        //pay loan base straight to lender contract
        //split interest amount into 70% to lender contract, 10% to DAO treasury, 20% to Delegate

    }

    /**@notice function to repay a loan
    @param loanNumber the loan number of the loan to be repaid
    @dev will have to update the fund transfer function to be exclusively payable in USDC*/
    function repayLoan(uint256 loanNumber) public onlyBorrower payable returns (bool){
        uint256 CurrentTime = block.timestamp;
        uint256 loanBase = _LoanNumberToLoanAgreement[loanNumber].loanAmount;
        uint256 LoanValue = _LoanNumberToLoanAgreement[loanNumber].loanAmount;
        uint256 CreationTime = _LoanNumberToLoanAgreement[loanNumber].creationTime;
        if(checkOverdue(loanNumber) == true){
            emit loanOverdue(loanNumber, _LoanNumberToLoanAgreement[loanNumber].maturityTime, block.timestamp);
        }
        require(CurrentTime >  CreationTime + 86400, "ERROR: Loan created less than a day ago"); //86400 seconds = 1 day
        uint256 daysSinceCreation = (CurrentTime - CreationTime)/86400; //should return a floor value
        for(uint256 i = 1; i<=daysSinceCreation; i++){
            LoanValue = LoanValue + (LoanValue * rate);
        }
        _LoanNumberToLoanAgreement[loanNumber].loanAmount = LoanValue;

        //fund transfer occurs for amount of loan value

        require(_LoanNumberToLoanAgreement[loanNumber].loanAmount == msg.value, "ERROR: msg.value not equal to outstanding loan amount");

        //if loan value transfer is successful - update loanRepaid to true and return true,
        //else return false and tx bounces. Either that or include same logic via require statement
        return true;
    }

    function checkAccess() public hasAccess returns (uint256){
      return 1;
    }

    /** @notice function call to check for all overdue loans any overdue loans*/
    function checkAll() view public returns (uint256[] memory) {
        uint256[] memory overdueLoans;
        uint256 length = 0;
        for (uint256 i = 1; i<=globalLoanNumber; i++){
            if(_LoanNumberToLoanAgreement[i].loanActive == true) {
                if(checkOverdue(i) == true){
                    if(length != 0){
                        length++;
                    }
                    overdueLoans[length] = i;
                }
            }
        }
        return overdueLoans;
    }

    /** @notice function call used to 'deprecate' a loan - called when a loan has been fully repaid
        @param loanNumber the loanNumber for the loan to be deprecated */
    function deprecateLoan(uint256 loanNumber) public onlyOwner returns (uint256) {
        require(_LoanNumberToLoanAgreement[loanNumber].loanActive == true, "ERROR: Loan already inactive");
        require(_LoanNumberToLoanAgreement[loanNumber].loanRepaid == true, "ERROR: Loan has not been repaid");
        _LoanNumberToLoanAgreement[loanNumber].loanActive = false;
        emit loanDeprecated(loanNumber, _LoanNumberToLoanAgreement[loanNumber].loanAmount, _LoanNumberToLoanAgreement[loanNumber].loanDuration,
        _LoanNumberToLoanAgreement[loanNumber].creationTime, _LoanNumberToLoanAgreement[loanNumber].maturityTime,
        _LoanNumberToLoanAgreement[loanNumber].loanRepaid);
        return loanNumber;
    }

    /**
      Function to test roles
    */
    function ownerRole(address a) public view returns (bool) {
      return hasRole(OWNER_ROLE, a);
    }

    function grantLender(address a) onlyOwner public {
      grantRole(LENDER_ROLE, a);

    }

    function grantBorrower(address a) onlyOwner public {
      grantRole(BORROWER_ROLE, a);
    }

    function grantDelegate(address a) onlyOwner public {
      grantRole(DELEGATE_ROLE, a);
    }

    modifier onlyDelegate() {
      require(hasRole(DELEGATE_ROLE, _msgSender()), "Must be a delegate");
      _;
    }

    modifier onlyLender() {
      require(hasRole(LENDER_ROLE, _msgSender()), "Must be a lender");
      _;
    }

    modifier onlyBorrower() {
      require(hasRole(BORROWER_ROLE, _msgSender()), "Must be a borrower");
      _;
    }

    modifier onlyOwner() {
      require(hasRole(OWNER_ROLE, _msgSender()), "Must be an owner");
      _;
    }

    modifier hasAccess() {
      require(hasRole(OWNER_ROLE, _msgSender()) || hasRole(LENDER_ROLE, _msgSender()) || hasRole(DELEGATE_ROLE, _msgSender()) || hasRole(BORROWER_ROLE, _msgSender()), "Caller must have a role to access function call");
      _;
    }

}
