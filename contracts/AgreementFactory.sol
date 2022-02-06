pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AgreementFactory is Ownable {
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

    //will also need to add in {address agentWhitelist, address userWhitelist} into the constructor
    constructor(address DelegateAddress) public {
        globalLoanNumber = 1;
        delegateAddress = DelegateAddress;
    }
    
    /** @notice function call used for creating loan agreements
        @param Rate interest rate involved in the loanAgreement
        @param LoanAmount amount issued in the loan
        @param LoanDuration duration of the created loan*/
    function createLoanAgreement(uint256 LoanAmount, uint256 LoanDuration, uint256 Rate) public returns (uint256) {
        uint256 newLoanNumber = globalLoanNumber;
        LoanAgreement memory loanAgreement;
        uint256 currentTime = block.timestamp;
        uint256 expiryTimestamp = currentTime + 100; //Change 100 to be a dynamic variable equal to the loan duration
        loanAgreement = LoanAgreement(Rate, LoanAmount, LoanDuration, msg.sender, currentTime, expiryTimestamp, false, false, false);
        _LoanNumberToLoanAgreement[newLoanNumber] = loanAgreement;
        globalLoanNumber++;
        emit loanCreated(newLoanNumber, Rate, LoanAmount, LoanDuration, msg.sender);
        return newLoanNumber;
    }

    /** @notice function used to execute an existing loan agreement
        @param loanNumber the loan number for the loan to be executed */
    function ExecuteLoanAgreement(uint256 loanNumber) public payable returns (bool) {
        require(_LoanNumberToLoanAgreement[loanNumber].delegateVerified = true, "ERROR: Loan not verified by delegate wallet");
        _LoanNumberToLoanAgreement[loanNumber].loanActive = true;
        address payable userAd = payable(_LoanNumberToLoanAgreement[loanNumber].borrowerAddress);

        //fund transfer executes here
        bool valueTransfer = userAd.send(_LoanNumberToLoanAgreement[loanNumber].loanAmount);
        require(valueTransfer == true, "ERROR: Could not execute value transfer");

        emit loanApproved(loanNumber, _LoanNumberToLoanAgreement[loanNumber].rate, _LoanNumberToLoanAgreement[loanNumber].loanAmount, 
        _LoanNumberToLoanAgreement[loanNumber].loanDuration,_LoanNumberToLoanAgreement[loanNumber].borrowerAddress, 
        _LoanNumberToLoanAgreement[loanNumber].delegateVerified);
        return _LoanNumberToLoanAgreement[loanNumber].loanActive;
    }


    /** @notice function call for the delegate wallet to verify the loan agreement
        @param loanNumber the loan number that the verification is for
        @dev ideally we will be able to remove this function and have this verification performed through ethereum signing*/
    function DelegateVerify(uint256 loanNumber) public returns (bool) {
        require(msg.sender == delegateAddress, "ERROR: DelegateVerify only callable by Delegate Wallet");
        _LoanNumberToLoanAgreement[loanNumber].delegateVerified = true;
        return _LoanNumberToLoanAgreement[loanNumber].delegateVerified;
    }

    /**@notice function to repay a loan */
    function repayLoan(uint256 loanNumber) public payable returns (bool){
        uint256 CurrentTime = block.timestamp;
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

        //if loan value transfer is successful - update loanRepaid to true and return true, 
        //else return false and tx bounces. Either that or include same logic via require statement
        return true;
    }

    /**@notice function call to check if a loan is overdue
    @param loanNumber the loan number that is checked if past maturity*/
    function checkOverdue(uint256 loanNumber) view public returns (bool) {
        if(_LoanNumberToLoanAgreement[loanNumber].maturityTime < block.timestamp){
            return true;
        }
        else{
            return false;
        }
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
    function deprecateLoan(uint256 loanNumber) public returns (uint256) {
        require(_LoanNumberToLoanAgreement[loanNumber].loanActive == true, "ERROR: Loan already inactive");
        require(_LoanNumberToLoanAgreement[loanNumber].loanRepaid == true, "ERROR: Loan has not been repaid");
        _LoanNumberToLoanAgreement[loanNumber].loanActive = false;
        emit loanDeprecated(loanNumber, _LoanNumberToLoanAgreement[loanNumber].loanAmount, _LoanNumberToLoanAgreement[loanNumber].loanDuration, 
        _LoanNumberToLoanAgreement[loanNumber].creationTime, _LoanNumberToLoanAgreement[loanNumber].maturityTime, 
        _LoanNumberToLoanAgreement[loanNumber].loanRepaid);

        return loanNumber;
    }

} 