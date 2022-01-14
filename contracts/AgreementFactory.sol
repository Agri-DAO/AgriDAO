pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AgreementFactory is Ownable {
    uint256 public globalLoanNumber;
    uint256 public rate;
    uint256 public agentCommission;
    uint256 public loanAmount;
    uint256 public loanDuration;
    address public agentAddress;
    address public userAddress;
    uint256 public creationTime;
    uint256 public maturityTime;
    bool public loanRepaid;
    address public ottleyAddress;
    bool public ottleyVerified;
    bool public agentVerified;
    bool public loanActive;

    struct LoanAgreement {
        uint256 rate;
        uint256 agentCommission;
        uint256 loanAmount;
        uint256 loanDuration;
        address agentAddress;
        address userAddress;
        //bool agentWhitelist; -> implemented at a later date
        //bool userWhitelist; -> implemented at a later date
        uint256 creationTime;
        uint256 maturityTime;
        bool loanRepaid;
        bool ottleyVerified;
        bool agentVerified;
        bool loanActive;
        bool loanOverdue;
    }

    //mapping loanNumber to LoanAgreement struct
    mapping(uint256 => LoanAgreement) public _LoanNumberToLoanAgreement;  

    event loanCreated(uint256 LoanNumber, uint256 Rate, uint256 LoanAmount, uint256 LoanDuration, address AgentAddress, address UserAddress);
    event loanDeprecated(uint256 LoanNumber, uint256 LoanAmount, uint256 creationTime, uint256 maturityTime, uint256 DaysOverdue, bool LoanRepaid);
    event loanApproved(uint256 LoanNumber, uint256 Rate, uint256 LoanAmount, uint256 LoanDuration, address AgentAddress, address UserAddress, 
            bool OttleyVerified, bool AgentVerified);
    event loanOverdue(uint256 LoanNumber, uint256 updateBlockTime);

    //will also need to add in {address agentWhitelist, address userWhitelist} into the constructor
    constructor(address OttleyWallet) public {
        globalLoanNumber = 1;
        ottleyAddress = OttleyWallet;
    }
    
    /** @notice function call used for creating loan agreements
        @param Rate interest rate involved in the loanAgreement
        @param LoanAmount amount issued in the loan
        @param LoanDuration duration of the created loan*/
    function createLoanAgreement(uint256 LoanAmount, uint256 LoanDuration, uint256 Rate, address AgentAddress) public returns (uint256) {
        //require agent address to be on agentWhitelist
        //require user address to be on userWhitelist
        uint256 newLoanNumber = globalLoanNumber;
        LoanAgreement memory loanAgreement;
        uint256 currentTime = block.timestamp;
        uint256 expiryTimestamp = currentTime + 100; //Change 100 to be a dynamic variable equal to the loan duration
        loanAgreement = LoanAgreement(Rate, 0, LoanAmount, LoanDuration, AgentAddress, msg.sender, currentTime, expiryTimestamp, false, false, false, false, false);
        _LoanNumberToLoanAgreement[newLoanNumber] = loanAgreement;
        globalLoanNumber++;
        emit loanCreated(newLoanNumber, Rate, LoanAmount, LoanDuration, AgentAddress, msg.sender);
        return newLoanNumber;
    }

    /** @notice function used to execute an existing loan agreement
        @param loanNumber the loan number for the loan to be executed */
    function ExecuteLoanAgreement(uint256 loanNumber) public payable returns (bool) {
        require(_LoanNumberToLoanAgreement[loanNumber].ottleyVerified = true, "ERROR: Loan not verified by Ottley Wallet");
        require(_LoanNumberToLoanAgreement[loanNumber].agentVerified = true, "ERROR: Loan not verified by agent");
        _LoanNumberToLoanAgreement[loanNumber].loanActive = true;
        address payable userAd = payable(_LoanNumberToLoanAgreement[loanNumber].userAddress);

        //fund transfer executes here
        bool valueTransfer = userAd.send(_LoanNumberToLoanAgreement[loanNumber].loanAmount);
        require(valueTransfer == true, "ERROR: Could not execute value transfer");

        emit loanApproved(loanNumber, _LoanNumberToLoanAgreement[loanNumber].rate, _LoanNumberToLoanAgreement[loanNumber].loanAmount, 
        _LoanNumberToLoanAgreement[loanNumber].loanDuration, _LoanNumberToLoanAgreement[loanNumber].agentAddress, 
        _LoanNumberToLoanAgreement[loanNumber].userAddress, _LoanNumberToLoanAgreement[loanNumber].ottleyVerified, 
        _LoanNumberToLoanAgreement[loanNumber].agentVerified);
        return _LoanNumberToLoanAgreement[loanNumber].loanActive;
    }

    /** @notice function call for the Ottley wallet to verify the loan agreement
        @param loanNumber the loan number that the verification is for
        @dev ideally we will be able to remove this function and have this verification performed through ethereum signing*/
    function OttleyVerify(uint256 loanNumber) public returns (bool) {
        require(msg.sender == ottleyAddress, "ERROR: OttleyVerify only callable by Ottley Capital Wallet");
        _LoanNumberToLoanAgreement[loanNumber].ottleyVerified = true;
        return _LoanNumberToLoanAgreement[loanNumber].ottleyVerified;
    }

    /** @notice function call for the Agent to verify the loan agreement
        @param loanNumber the loan number that the verification is for
        @dev ideally we will be able to remove this function and have this verification performed through ethereum signing */
    function AgentVerify(uint256 loanNumber) public returns (bool){
        address AgentWallet = _LoanNumberToLoanAgreement[loanNumber].agentAddress;
        require(msg.sender == AgentWallet, "ERROR: AgentVerify only callable by designated Agent wallet");
        _LoanNumberToLoanAgreement[loanNumber].agentVerified = true;
        return _LoanNumberToLoanAgreement[loanNumber].agentVerified;
    }

    function checkOverdue(uint256 loanNumber) view public returns (bool) {
        if(_LoanNumberToLoanAgreement[loanNumber].maturityTime < block.timestamp){
            return true;
        }
        else{
            return false;
        }
    }

    /** @notice function call to check if there are any overdue loans*/
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

    /** @notice function call used to rebase a specific loan
        @param LoanNumber the LoanNumber of the loan to be rebased
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
    REBASING SYSTEM REMOVED*/

    /** @notice function call used to 'deprecate' a loan - called when a loan has been fully repaid
        @param loanNumber the loanNumber for the loan to be deprecated */
    function deprecateLoan(uint256 loanNumber) public returns (uint256) {
        require(_LoanNumberToLoanAgreement[loanNumber].loanActive == true, "ERROR: Loan already inactive");
        require(_LoanNumberToLoanAgreement[loanNumber].loanRepaid == true, "ERROR: Loan has not been repaid");
        
        //route fee to agent account

        _LoanNumberToLoanAgreement[loanNumber].loanActive = false;

        emit loanDeprecated(loanNumber, _LoanNumberToLoanAgreement[loanNumber].loanAmount, _LoanNumberToLoanAgreement[loanNumber].loanDuration, 
        _LoanNumberToLoanAgreement[loanNumber].creationTime, _LoanNumberToLoanAgreement[loanNumber].maturityTime, 
        _LoanNumberToLoanAgreement[loanNumber].loanRepaid);

        return loanNumber;
    }

} 