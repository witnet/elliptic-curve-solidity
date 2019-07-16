var scalardecompose = artifacts.require("./ScalarDecompose.sol")

module.exports = function (deployer) {
  deployer.deploy(scalardecompose)
}
