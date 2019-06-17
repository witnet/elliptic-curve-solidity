var EC = artifacts.require("./EcUtils.sol")

module.exports = function (deployer, network, accounts) {
  console.log("Network:", network)
  deployer.deploy(EC)
}
