const { expect } = require("chai");
const { utils, Signer } = require("ethers");
const { ethers } = require("hardhat");

describe("Deployments", function () {
    it("Should successfully Deploy the contracts", async function () {
        const BorrowerLogic = await ethers.getContractFactory("BorrowerLogic");
        let accounts = await hre.ethers.getSigners();
        let owner = accounts[0];
        let delegate = accounts[1];
        let lender = accounts[2];
        let treasury = accounts[3];
        const borrowerLogic = await BorrowerLogic.deploy(delegate.address, lender.address, treasury.address);
    });
});

describe("creating and executing a loan", function () {
    it("Should be able to successfully create a loan agreement", async function (){
        const BorrowerLogic = await ethers.getContractFactory("BorrowerLogic");
        let accounts = await hre.ethers.getSigners();
        let owner = accounts[0];
        let delegate = accounts[1];
        let lender = accounts[2];
        let treasury = accounts[3];
        const borrowerLogic = await BorrowerLogic.deploy(delegate.address, lender.address, treasury.address);
        borrowerLogic.grantLender(lender.address);
        borrowerLogic.grantDelegate(delegate.address);
        const loanID = await borrowerLogic.connect(lender).createLoanAgreement(ethers.utils.parseEther("10"), 180, 6);
        await borrowerLogic.connect(delegate).delegateVerify(1);
        const loanExecuted = await borrowerLogic.executeLoanAgreement(1, {value: ethers.utils.parseEther("10")});

        console.log(loanExecuted);

    });

describe("Testing Access Control", function() {
    before(async function () {
        this.accounts = await hre.ethers.getSigners();
        this.Borrow = await ethers.getContractFactory("BorrowerLogic");
    });

    beforeEach(async function() {
      this.owner = this.accounts[0];
      this.delegate = this.accounts[1];
      this.lender = this.accounts[2];
      this.treasury = this.accounts[3];
      this.borrow = await this.Borrow.deploy(this.delegate.address, this.lender.address, this.treasury.address);
    })

    it("Should throw an error when a non-lender account tries to create a loan", async function() {
      await expect(this.borrow.connect(this.delegate).createLoanAgreement(10, 180, 6)).to.be.reverted;
    })

    it("Should throw an error when an account with no access attempts to call function", async function() {
      await expect(this.borrow.connect(this.treasury).checkAccess()).to.be.reverted;
    })

    it("Should only allow a delegator role to verify", async function () {
      await this.borrow.grantDelegate(this.delegate.address);
      await expect(this.borrow.connect(this.delegate).delegateVerify(1));
    })

    it("Should only allow for a lender to create a loan agreement", async function() {
      await this.borrow.grantLender(this.lender.address);
      await expect(this.borrow.connect(this.lender).createLoanAgreement(10, 180, 6));
    })

    

});

});

describe("repaying a loan", function () {});
