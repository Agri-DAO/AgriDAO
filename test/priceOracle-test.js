const { expect } = require("chai");
const { utils, Signer } = require("ethers");
const { ethers } = require("hardhat");

describe("Deployments", function () {
    it("Should successfully Deploy the contracts", async function () {
        const PriceOracle = await ethers.getContractFactory("OraclePrice");
        let accounts = await hre.ethers.getSigners();
        let owner = accounts[0];
        const priceOracle = await PriceOracle.deploy();
        let price = await priceOracle.getPrice("USDC/ETH");
        console.log(price)
    });
});

