const BN = web3.utils.BN
const EcUtils = artifacts.require("EcUtils")

contract("EcUtils", accounts => {
  describe("secp256k1", () => {
    // var n = new BN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F", 16)
    // const gx = new BN("79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798", 16)
    // const gy = new BN("483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8", 16)
    const pp = new BN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F", 16)
    let ecUtils
    before(async () => {
      ecUtils = await EcUtils.deployed()
    })
    it("Should convert a Jacobian point to affine", async () => {
      var x = web3.utils.toBN("0x189AFAF398F5708CD7343C6AF8B9A22CC64B6BD80DF3623F5FE0E1B9D024F450")
      var y = web3.utils.toBN("0xD1BFE9B7A1C5204AFB7448337815003FEE8BA4B9C78DFE2D2460C3971117F59")
      var z = web3.utils.toBN("0xF167A208BEA79BC52668C016AFF174622837F780AB60F59DFED0A8E66BB7C2AD")

      const affine = await ecUtils.toZ1(x, y, z, pp)
      var expectedX = web3.utils.toBN("0xC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5")
      var expectedY = web3.utils.toBN("0x1AE168FEA63DC339A3C58419466CEAEEF7F632653266D0E1236431A950CFE52A")

      assert.equal(affine[0].toString(), expectedX.toString())
      assert.equal(affine[1].toString(), expectedY.toString())
    })
    it("Should Calculate inverse", function (done) {
      var d = new BN(2)
      ecUtils._inverse(d, function (err, inv) {
        assert.ifError(err)
        ecUtils._jMul(d, 1, inv, 1, function (err, res) {
          assert.ifError(err)
          var x3 = res[0]
          var z3 = res[1]
          assert.equal(x3.toString(10), "1")
          assert.equal(z3.toString(10), "1")
          done()
        })
      })
    })
    it("Inverse of 0", function (done) {
      var d = new BN(0)
      ecUtils._inverse(d, function (err, inv) {
        assert.ifError(err)
        assert.equal(inv.toString(10), "0")
        done()
      })
    })
    it("Inverse of 1", function (done) {
      var d = new BN(1)
      ecUtils._inverse(d, function (err, inv) {
        assert.ifError(err)
        assert.equal(inv.toString(10), "1")
        done()
      })
    })
    it("Should Calculate inverse -1", function (done) {
      var d = pp.sub(1)
      ecUtils._inverse(d, function (err, inv) {
        assert.ifError(err)
        ecUtils._jMul(d, 1, inv, 1, function (err, res) {
          assert.ifError(err)
          var x3 = res[0]
          var z3 = res[1]
          assert.equal(x3.toString(10), "1")
          assert.equal(z3.toString(10), "1")
          done()
        })
      })
    })
    it("Should Calculate inverse -2", function (done) {
      var d = pp.sub(1)
      ecUtils._inverse(d, function (err, inv) {
        assert.ifError(err)
        ecUtils._jMul(d, 1, inv, 1, function (err, res) {
          assert.ifError(err)
          var x3 = res[0]
          var z3 = res[1]
          assert.equal(x3.toString(10), "1")
          assert.equal(z3.toString(10), "1")
          done()
        })
      })
    })
    it("Should Calculate inverse big number", function (done) {
      var d = new BN("f167a208bea79bc52668c016aff174622837f780ab60f59dfed0a8e66bb7c2ad", 16)
      ecUtils._inverse(d, function (err, inv) {
        assert.ifError(err)
        ecUtils._jMul(d, 1, inv, 1, function (err, res) {
          assert.ifError(err)
          var x3 = res[0]
          var z3 = res[1]
          assert.equal(x3.toString(10), "1")
          assert.equal(z3.toString(10), "1")
          done()
        })
      })
    })
  })
})
