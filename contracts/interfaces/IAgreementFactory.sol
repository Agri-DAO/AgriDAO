pragma solidity ^0.8.4;

interface IAgreementFactory {
/** @notice function call used for creating loan agreements
        @param Rate interest rate involved in the loanAgreement
        @param LoanAmount amount issued in the loan
        @param LoanDuration duration of the created loan*/
    function createLoanAgreement(uint256 LoanAmount, uint256 LoanDuration, uint256 Rate, address AgentAddress) external returns (uint256);

    /** @notice function used to execute an existing loan agreement
        @param LoanNumber the loan number for the loan to be executed */
    function ExecuteLoanAgreement(uint256 LoanNumber) external payable returns (bool);
    
    /** @notice function call for the Ottley wallet to verify the loan agreement
        @param LoanNumber the loan number that the verification is for
        @dev ideally we will be able to remove this function and have this verification performed through ethereum signing*/
    function OttleyVerify(uint256 LoanNumber) external returns (bool);

    /**@notice function to repay a loan */
    function repayLoan(uint256 loanNumber) external payable returns (bool);

    /**@notice function call to check if a loan is overdue
    @param loanNumber the loan number that is checked if past maturity*/
    function checkOverdue(uint256 loanNumber) external view returns (bool);

    /** @notice function call to check for all overdue loans any overdue loans*/
    function checkAll() external view returns (uint256[] memory);

    /** @notice function call used to 'deprecate' a loan - called when a loan has been fully repaid
        @param LoanNumber the loanNumber for the loan to be deprecated */
    function deprecateLoan(uint256 LoanNumber) external returns (uint256);
}