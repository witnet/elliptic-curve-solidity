const BN = web3.utils.BN
const ScalarDecompose = artifacts.require("./ScalarDecompose")

contract("ScalarDecompose", accounts => {
  describe("div", () => {
    let scalarDec
    before(async () => {
      scalarDec = await ScalarDecompose.new()
    })
    // Test vector gotten by https://github.com/witnet/vrf-rs and verified in ./test/TestNumerology
    it("Should decompose a scalar", async () => {
      // Decomposing 75248613030864893108242641597194458900902101953482987138755842533112887212911 (s in vrf-rs)

      var x = web3.utils.toBN("0xA65D34A6D90A8A2461E5DB9205D4CF0BB4B2C31B5EF6997A585A9F1A72517B6F")

      const decomposed = await scalarDec.roundedsplitDiv(x)
      var expectedk1 = web3.utils.toBN("0x1f2190550d1a3d6bcd73a35b3ae52d6cb7a585a9f1a72517b6f")
      var expectedk2 = web3.utils.toBN("0xbfde79ae524aed634b60235a0285c122000000000000000000")

      assert.equal(decomposed[0].toString(), expectedk1.toString())
      assert.equal(decomposed[1].toString(), expectedk2.toString())
    })
    // Test vector gotten by https://github.com/witnet/vrf-rs and verified in ./test/TestNumerology
    it("Should decompose a scalar 2", async () => {
      // Decomposing 115792089237316195423570985008687907852809678225568584106548306634520350375856 (c inverse in vrf-rs)
      var x = web3.utils.toBN("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEA5B4345017941D611C5A632185AB3FB0")

      const decomposed = await scalarDec.roundedsplitDiv(x)
      var expectedk1 = web3.utils.toBN("0x22392EA2495B53A20EB53D0AADDFC881611C5A632185AB3FB0")
      var expectedk2 = web3.utils.toBN("0x34545F9AD3ADD73BD81EF6093C0DF51C000000000000000000")

      assert.equal(decomposed[0].toString(), expectedk1.toString())
      assert.equal(decomposed[1].toString(), expectedk2.toString())
    })
    // Test vector gotten by https://chuckbatson.wordpress.com/2014/11/26/secp256k1-test-vectors/ and verified in ./test/TestNumerology
    it("Should decompose a scalar 3", async () => {
      // Decomposing 112233445566778899
      var x = web3.utils.toBN("0x18EBBB95EED0E13")

      const decomposed = await scalarDec.roundedsplitDiv(x)
      var expectedk1 = web3.utils.toBN("0x18EBBB95EED0E13")
      var expectedk2 = web3.utils.toBN("0x00")

      assert.equal(decomposed[0].toString(), expectedk1.toString())
      assert.equal(decomposed[1].toString(), expectedk2.toString())
    })
    // Test vector gotten by https://chuckbatson.wordpress.com/2014/11/26/secp256k1-test-vectors/ and verified in ./test/TestNumerology
    it("Should decompose a scalar 4", async () => {
      // Decomposing 28948022309329048855892746252171976963209391069768726095651290785379540373584
      var x = web3.utils.toBN("0X3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFAEABB739ABD2280EEFF497A3340D9050")
      const decomposed = await scalarDec.roundedsplitDiv(x)
      var expectedk1 = web3.utils.toBN("0x88e4ba89256d4e883b28decd11ddf410eeff497a3340d9050")
      var expectedk2 = web3.utils.toBN("0xd1517e6b4eb75cef607bd824f037d47000000000000000000")

      assert.equal(decomposed[0].toString(), expectedk1.toString())
      assert.equal(decomposed[1].toString(), expectedk2.toString())
    })
    // Test vector gotten by https://chuckbatson.wordpress.com/2014/11/26/secp256k1-test-vectors/ and verified in ./test/TestNumerology
    it("Should decompose a scalar 5", async () => {
      // Decomposing 57896044618658097711785492504343953926418782139537452191302581570759080747168
      var x = web3.utils.toBN("0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0")
      const decomposed = await scalarDec.roundedsplitDiv(x)
      var expectedk1 = web3.utils.toBN("0x111c975124ada9d107651bd9a23bbe821ddfe92f46681b20a0")
      var expectedk2 = web3.utils.toBN("0x1a2a2fcd69d6eb9dec0f7b049e06fa8e000000000000000000")

      assert.equal(decomposed[0].toString(), expectedk1.toString())
      assert.equal(decomposed[1].toString(), expectedk2.toString())
    })
    // Test vector gotten by https://chuckbatson.wordpress.com/2014/11/26/secp256k1-test-vectors/ and verified in ./test/TestNumerology
    it("Should decompose a scalar 7", async () => {
      // Decomposing 86844066927987146567678238756515930889628173209306178286953872356138621120752
      var x = web3.utils.toBN("0xBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0C0325AD0376782CCFDDC6E99C28B0F0")

      const decomposed = await scalarDec.roundedsplitDiv(x)
      var expectedk1 = web3.utils.toBN("0xFFFFFFFFFFFFFE209D132C0D13029AC2BCC86CB20431C8688FB025766C5EF231")
      var expectedk2 = web3.utils.toBN("0xFFFFFFFFFFFFFEE1EE249ACE0B01A8A0A445F1A3F005883BBFD25E8CD0364141")

      assert.equal(decomposed[0].toString(), expectedk1.toString())
      assert.equal(decomposed[1].toString(), expectedk2.toString())
    })   
  })
})
