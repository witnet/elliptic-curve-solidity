var eclib = artifacts.require("./EllipticCurve.sol")

module.exports = function (deployer) {
  deployer.deploy(eclib)
}
