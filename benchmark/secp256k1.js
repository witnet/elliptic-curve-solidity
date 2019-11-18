const EllipticCurve = artifacts.require("../contracts/EllipticCurve")
const Secp256k1GasHelper = artifacts.require("./Secp256k1GasHelper")
const testdata = require("./secp256k1-data.json")

contract("Secp256k1 - Gas consumption analysis", accounts => {
  describe("Public Key Derivation", () => {
    let helper
    before(async () => {
      await EllipticCurve.deployed()
      await Secp256k1GasHelper.link(EllipticCurve)
      helper = await Secp256k1GasHelper.new()
    })
    it("Should derive a public key", async () => {
      for (const pair of testdata.keypairs) {
        var priv = web3.utils.toBN(pair.priv)
        await helper.derivePubKey(priv)
      }
    })
  })
})
