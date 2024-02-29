const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../scripts/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    let args = [];
    log("----------------------------------------------------");
    const nftMarketplace = await deploy("NftMarketPlace", {
        from: deployer,
        log: true,
        args: args,
        waitConfirmations: network.config.blockConfirmations
    });
    if (!developmentChains.includes(network.name) && process.env.ETHERSCANAPIKEY) {
        log("Verifying the contract....");
        await verify(nftMarketplace.address, args);
        log("Verification completed...");
    }
};

module.exports.tags = ["all", "NftMarketPlace"];