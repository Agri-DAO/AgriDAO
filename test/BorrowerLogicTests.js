const { expect } = require("chai");
const { utils, Signer } = require("ethers");
const { ethers } = require("hardhat");

describe("Deployments", function () {
    it("Should successfully Deploy the contracts", async function () {
        const BorrowerLogic = await ethers.getContractFactory("Borrower");
        let accounts = await hre.ethers.getSigners();
        let owner = accounts[0];
        const borrowerLogic = await BorrowerLogic.deploy(owner.address, accounts[1], accounts[2]);
    });
});

describe("creating and executing a loan", function () {
    it("Should be able to successfully create a loan agreement", async function (){
        const BorrowerLogic = await ethers.getContractFactory("Borrower");
        let accounts = await hre.ethers.getSigners();
        let owner = accounts[0];
        const borrowerLogic = await BorrowerLogic.deploy(owner.address, accounts[1], accounts[2]);
    });

});

describe("repaying a loan", function () {});

