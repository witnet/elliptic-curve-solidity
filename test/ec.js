const BN = web3.utils.BN
const EC = artifacts.require("EllipticCurve")

contract("EC", accounts => {
  describe("EC curve", () => {
    var n = new BN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F", 16)
    // const gx = new BN("79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798", 16)
    // const gy = new BN("483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8", 16)
    // const n2 = new BN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", 16)
    let ec
    before(async () => {
      ec = await EC.deployed()
    })
    it("Should Add two small numbers", async () => {
      var x1 = new BN(2)
      var z1 = new BN(3)
      var x2 = new BN(4)
      var z2 = new BN(5)
      const res = await ec._jAdd.call(x1, z1, x2, z2)
      var x3 = res[0]
      var z3 = res[1]
      assert.equal(x3.toString(10), "22")
      assert.equal(z3.toString(10), "15")
    })
    it("Should Add one big numbers with one small", async () => {
      var x1 = n.sub(web3.utils.toBN("1"))
      var z1 = new BN(1)
      var x2 = new BN(2)
      var z2 = new BN(1)
      const res = await ec._jAdd.call(x1, z1, x2, z2)
      var x3 = res[0]
      var z3 = res[1]
      assert.equal(x3.toString(10), "1")
      assert.equal(z3.toString(10), "1")
    })
    // To be continued...
    it("Should Invert an inverted number and be the same", async () => {
      const y1 = web3.utils.toBN("0x9d42bf0c35d765c2242712205e8f8b1ea588f470a6980b21bc9efb4ab33ae246")
      const inverted = await ec._invMod(y1)
      const newY1 = await ec._invMod(inverted)
      assert.equal(newY1.toString(), y1.toString())
    })

    it("Should Add two big numbers", async () => {
      const x1 = web3.utils.toBN("0x3596f1f475c8999ffe35ccf7cebee7373ee40513ad467e3fc38600aa06d41bcf")
      const z1 = web3.utils.toBN("0x825a3eb4f09a55637391c950ba5e25c1ea658a15f234c14ebec79e5c68bd4133")
      const x2 = web3.utils.toBN("0x1c2a90c4c30f60e878d1fe317acf4f2e059300e3deaa1c949628096ecaf993b2")
      const z2 = web3.utils.toBN("0x62bd40f3ca289a3ddbd8eddfa17074e15a770b8f5967f4de436104b44cc519e9")
      const res = await ec.ecAdd(x1, z1, x2, z2)
      const sumX = res[0]
      const sumZ = res[1]
      const expectedSumX = web3.utils.toBN("0x957f0c13905d357d9e1ebaf32742b410d423fcf2410229d4e8093f3360d07b2c")
      const expectedSumZ = web3.utils.toBN("0x9a0d14288d3906e052bdcf12c2a469da3e7449068b3e119300b792da964ed977")
      assert.equal(sumX.toString(10), expectedSumX.toString())
      assert.equal(sumZ.toString(10), expectedSumZ.toString())
    })
    it("Should Invert an ec point", async () => {
      const x = web3.utils.toBN("0x1c2a90c4c30f60e878d1fe317acf4f2e059300e3deaa1c949628096ecaf993b2")
      const y = web3.utils.toBN("0x9d42bf0c35d765c2242712205e8f8b1ea588f470a6980b21bc9efb4ab33ae246")
      const invertedPoint = await ec.ecInv(x, y)

      const expectedY = web3.utils.toBN("0x62bd40f3ca289a3ddbd8eddfa17074e15a770b8f5967f4de436104b44cc519e9")
      assert.equal(invertedPoint[0].toString(), x.toString())
      assert.equal(invertedPoint[1].toString(), expectedY.toString())
    })
    it("Should Sub two big numbers", async () => {
      const x1 = web3.utils.toBN("0x3596f1f475c8999ffe35ccf7cebee7373ee40513ad467e3fc38600aa06d41bcf")
      const z1 = web3.utils.toBN("0x825a3eb4f09a55637391c950ba5e25c1ea658a15f234c14ebec79e5c68bd4133")
      const x2 = web3.utils.toBN("0x1c2a90c4c30f60e878d1fe317acf4f2e059300e3deaa1c949628096ecaf993b2")
      const z2 = web3.utils.toBN("0x9d42bf0c35d765c2242712205e8f8b1ea588f470a6980b21bc9efb4ab33ae246")
      const res = await ec.ecSub(x1, z1, x2, z2)
      const sumX = res[0]
      const sumZ = res[1]
      const expectedSubX = web3.utils.toBN("0x957f0c13905d357d9e1ebaf32742b410d423fcf2410229d4e8093f3360d07b2c")
      const expectedSubY = web3.utils.toBN("0x9a0d14288d3906e052bdcf12c2a469da3e7449068b3e119300b792da964ed977")
      assert.equal(sumX.toString(10), expectedSubX.toString())
      assert.equal(sumZ.toString(10), expectedSubY.toString())
    })

    it("Should identify if point is on the curve", async () => {
      const x = web3.utils.toBN("0xe906a3b4379ddbff598994b2ff026766fb66424710776099b85111f23f8eebcc")
      const y = web3.utils.toBN("0x7638965bf85f5f2b6641324389ef2ffb99576ba72ec19d8411a5ea1dd251b112")
      assert.equal(await ec.isOnCurve(x, y), true)
    })

    it("Should identify if point is NOT on the curve", async () => {
      const x = web3.utils.toBN("0x3bf754f48bc7c5fb077736c7d2abe85354be649caa94971f907b3a81759e5b5e")
      const y = web3.utils.toBN("0x6b936ce0a2a40016bbb2eb0a4a1347b5af76a41d44b56dec26108269a45bce78")
      assert.equal(await ec.isOnCurve(x, y), false)
    })
  })
})
