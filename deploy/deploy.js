module.exports = async (hre) => {
    const { ethers } = hre
    const { deploy } = deployments
    const accounts = await ethers.getSigners()

    let priceOracle = await deploy("OraclePrice", {
      logs: true,
      from: accounts[0].address,
      args: [],
    })

    
    //verify the contract on deployment
    await hre.run("verify:verify", {
      address: priceOracle.address,
      constructorArguments: [],
    });
}

module.exports.tags = ["DeployLive"]
