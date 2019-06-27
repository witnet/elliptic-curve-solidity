const Secp256k1 = artifacts.require("./Secp256k1")
const testdata = require("./secp256k1-data.json")

contract("Example", accounts => {
  describe("secp256k1", () => {
    let example
    before(async () => {
      example = await Secp256k1.new()
    })
    it("Should derive a public key", async () => {
      for (let pair of testdata.keypairs) {
        var priv = web3.utils.toBN(pair.priv)
        await example.derivePubKey(priv)
      }
    })
  })
})
