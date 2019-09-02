var eclib = artifacts.require("./EllipticCurve.sol")
var fastEcMul = artifacts.require("./FastEcMul.sol")

module.exports = function (deployer) {
  fastEcMul.link(eclib)
  deployer.deploy(fastEcMul)
}
