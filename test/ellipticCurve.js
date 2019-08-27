const BN = web3.utils.BN
const EllipticCurve = artifacts.require("./EllipticCurve")

contract("EllipticCurve", accounts => {
  describe("secp256k1", () => {
    const gx = web3.utils.toBN("79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
    const gy = web3.utils.toBN("483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8")
    const pp = web3.utils.toBN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F")
    const n = web3.utils.toBN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141")
    const lambda = web3.utils.toBN("5363ad4cc05c30e0a5261c028812645a122e22ea20816678df02967c1b23bd72")
    const beta = web3.utils.toBN("7ae96a2b657c07106e64479eac3434e99cf0497512f58995c1396c28719501ee")
    let ecLib
    before(async () => {
      ecLib = await EllipticCurve.deployed()
    })
    it("Should convert a Jacobian point to affine", async () => {
      var x = web3.utils.toBN("0x7D152C041EA8E1DC2191843D1FA9DB55B68F88FEF695E2C791D40444B365AFC2")
      var y = web3.utils.toBN("0x56915849F52CC8F76F5FD7E4BF60DB4A43BF633E1B1383F85FE89164BFADCBDB")
      var z = web3.utils.toBN("0x9075B4EE4D4788CABB49F7F81C221151FA2F68914D0AA833388FA11FF621A970")

      const affine = await ecLib.toAffine(x, y, z, pp)
      var expectedY = web3.utils.toBN("0x1AE168FEA63DC339A3C58419466CEAEEF7F632653266D0E1236431A950CFE52A")
      var expectedX = web3.utils.toBN("0xC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5")

      assert.equal(affine[1].toString(), expectedY.toString())
      assert.equal(affine[0].toString(), expectedX.toString())
    })
    it("Invalid numbers", async () => {
      var d = new BN(0)
      try {
        // eslint-disable-next-line
        const inv = await ecLib.invMod(d, pp)
      } catch (error) {
        assert(error, "Invalid number")
      }
      try {
        // eslint-disable-next-line
        const inv = await ecLib.invMod(pp, d)
      } catch (error) {
        assert(error, "Invalid number")
      }
      try {
        // eslint-disable-next-line
        const inv = await ecLib.invMod(pp, pp)
      } catch (error) {
        assert(error, "Invalid number")
      }
    })
    it("Inverse of 1", async () => {
      var d = new BN(1)
      const inv = await ecLib.invMod(d, pp)
      assert.equal(inv.toString(10), "1")
    })
    it("Should Invert an inverted number and be the same", async () => {
      const y1 = web3.utils.toBN("0x9d42bf0c35d765c2242712205e8f8b1ea588f470a6980b21bc9efb4ab33ae246")
      const inverted = await ecLib.invMod(y1, pp)
      const newY1 = await ecLib.invMod(inverted, pp)
      assert.equal(newY1.toString(), y1.toString())
    })
    it("Should get the y coordinate based on parity", async () => {
      const coordX = "0xc2704fed5dc41d3979235b85edda8f86f1806c17ce0a516a034c605d2b4f9a26"
      const expectedCoordY = "0x6970c3dd18910d09250143db08fed1065a522403df0c204ed240a07d123b29d5"
      const coordY = await ecLib.deriveY(0x03, web3.utils.hexToBytes(coordX), 0, 7, pp)
      assert.equal(web3.utils.numberToHex(coordY), expectedCoordY)
    })
    it("Should identify if point is on the curve", async () => {
      const x = web3.utils.toBN("0xe906a3b4379ddbff598994b2ff026766fb66424710776099b85111f23f8eebcc")
      const y = web3.utils.toBN("0x7638965bf85f5f2b6641324389ef2ffb99576ba72ec19d8411a5ea1dd251b112")
      assert.equal(await ecLib.isOnCurve(x, y, 0, 7, pp), true)
    })
    it("Should identify if point is NOT on the curve", async () => {
      const x = web3.utils.toBN("0x3bf754f48bc7c5fb077736c7d2abe85354be649caa94971f907b3a81759e5b5e")
      const y = web3.utils.toBN("0x6b936ce0a2a40016bbb2eb0a4a1347b5af76a41d44b56dec26108269a45bce78")
      assert.equal(await ecLib.isOnCurve(x, y, 0, 7, pp), false)
    })
    it("Should Add two big numbers", async () => {
      const x1 = web3.utils.toBN("0x3596f1f475c8999ffe35ccf7cebee7373ee40513ad467e3fc38600aa06d41bcf")
      const z1 = web3.utils.toBN("0x825a3eb4f09a55637391c950ba5e25c1ea658a15f234c14ebec79e5c68bd4133")
      const x2 = web3.utils.toBN("0x1c2a90c4c30f60e878d1fe317acf4f2e059300e3deaa1c949628096ecaf993b2")
      const z2 = web3.utils.toBN("0x62bd40f3ca289a3ddbd8eddfa17074e15a770b8f5967f4de436104b44cc519e9")
      const res = await ecLib.ecAdd(x1, z1, x2, z2, 0, pp)
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
      const invertedPoint = await ecLib.ecInv(x, y, pp)

      const expectedY = web3.utils.toBN("0x62bd40f3ca289a3ddbd8eddfa17074e15a770b8f5967f4de436104b44cc519e9")
      assert.equal(invertedPoint[0].toString(), x.toString())
      assert.equal(invertedPoint[1].toString(), expectedY.toString())
    })
    it("Should Sub two big numbers", async () => {
      const x1 = web3.utils.toBN("0x3596f1f475c8999ffe35ccf7cebee7373ee40513ad467e3fc38600aa06d41bcf")
      const z1 = web3.utils.toBN("0x825a3eb4f09a55637391c950ba5e25c1ea658a15f234c14ebec79e5c68bd4133")
      const x2 = web3.utils.toBN("0x1c2a90c4c30f60e878d1fe317acf4f2e059300e3deaa1c949628096ecaf993b2")
      const z2 = web3.utils.toBN("0x9d42bf0c35d765c2242712205e8f8b1ea588f470a6980b21bc9efb4ab33ae246")
      const res = await ecLib.ecSub(x1, z1, x2, z2, 0, pp)
      const sumX = res[0]
      const sumZ = res[1]
      const expectedSubX = web3.utils.toBN("0x957f0c13905d357d9e1ebaf32742b410d423fcf2410229d4e8093f3360d07b2c")
      const expectedSubY = web3.utils.toBN("0x9a0d14288d3906e052bdcf12c2a469da3e7449068b3e119300b792da964ed977")
      assert.equal(sumX.toString(10), expectedSubX.toString())
      assert.equal(sumZ.toString(10), expectedSubY.toString())
    })
    it("Should double EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const res = await ecLib.ecAdd(x1, y1, x1, y1, 0, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0xC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5")
      const expectedMulY = web3.utils.toBN("0x1AE168FEA63DC339A3C58419466CEAEEF7F632653266D0E1236431A950CFE52A")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should Add two big numbers", async () => {
      const x1 = web3.utils.toBN("0xC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5")
      const z1 = web3.utils.toBN("0x1AE168FEA63DC339A3C58419466CEAEEF7F632653266D0E1236431A950CFE52A")
      const res = await ecLib.ecAdd(x1, z1, 0, 0, 0, pp)
      const sumX = res[0]
      const sumZ = res[1]
      assert.equal(sumX.toString(10), x1.toString())
      assert.equal(sumZ.toString(10), z1.toString())
    })
    it("Should multiply x2 EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x02")
      const res = await ecLib.ecMul(d, x1, y1, 0, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0xC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5")
      const expectedMulY = web3.utils.toBN("0x1AE168FEA63DC339A3C58419466CEAEEF7F632653266D0E1236431A950CFE52A")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should multiply big scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140")
      const res = await ecLib.ecMul(d, x1, y1, 0, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
      const expectedMulY = web3.utils.toBN("0xB7C52588D95C3B9AA25B0403F1EEF75702E84BB7597AABE663B82F6F04EF2777")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should multiply small scalar with EcPoint", async () => {
      const x1 = web3.utils.toBN("0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
      const y1 = web3.utils.toBN("0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8")
      const d = web3.utils.toBN("0x05")
      const res = await ecLib.ecMul(d, x1, y1, 0, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0x2F8BDE4D1A07209355B4A7250A5C5128E88B84BDDC619AB7CBA8D569B240EFE4")
      const expectedMulY = web3.utils.toBN("0xD8AC222636E5E3D6D4DBA9DDA6C9C426F788271BAB0D6840DCA87D3AA6AC62D6")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should test scalar decomposition multiplication 1", async () => {
      //const k1 = web3.utils.toBN("-89243190524605339210527649141408088119")
      //const k2 = web3.utils.toBN("-53877858828609620138203152946894934485")
      const k = web3.utils.toBN("77059549740374936337596179780007572461065571555507600191520924336939429631266")
      const kDecom = await ecLib.scalarDecomposition(k, n, lambda)
      //const l1 = web3.utils.toBN("-185204247857117235934281322466442848518")
      //const l2 = web3.utils.toBN("-7585701889390054782280085152653861472")
      const l = web3.utils.toBN("32670510020758816978083085130507043184471273380659243275938904335757337482424")
      const lDecom = await ecLib.scalarDecomposition(l, n, lambda)
      const P1 = web3.utils.toBN("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
      const P2 = web3.utils.toBN("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
      const Q1 = web3.utils.toBN("0xc6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5")
      const Q2 = web3.utils.toBN("0x1ae168fea63dc339a3c58419466ceaeef7f632653266d0e1236431a950cfe52a")
      const resJac = await ecLib._sim_mul([kDecom[0], kDecom[1], lDecom[0], lDecom[1]], [P1, P2, Q1, Q2], 0, beta, pp)
      const res_affine = await ecLib.toAffine(resJac[0], resJac[1], resJac[2], pp)
      const mulX = res_affine[0]
      const mulY = res_affine[1]
      const expectedMulX = web3.utils.toBN("0x7635e27fba8e1f779dcfdde1b1eacbe0571fbe39ecf6056d29ba4bd3ef5e22f2")
      const expectedMulY = web3.utils.toBN("0x197888e5cec769ac2f1eb65dbcbc0e49c00a8cdf01f8030d8286b68c1933fb18")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulY.toString(10), expectedMulY.toString())
    })
    it("Should test scalar decomposition multiplication 2", async () => {
      const k = web3.utils.toBN("115792089237316195423570985008687907852837564279074904382605163141518161494329")
      const kDecom = await ecLib.scalarDecomposition(k, n, lambda)
      const l = web3.utils.toBN("1")
      const lDecom = await ecLib.scalarDecomposition(l, n, lambda)
      const P1 = web3.utils.toBN("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
      const P2 = web3.utils.toBN("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
      const Q1 = web3.utils.toBN("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
      const Q2 = web3.utils.toBN("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
      const resJac = await ecLib._sim_mul([kDecom[0], kDecom[1], lDecom[0], lDecom[1]], [P1, P2, Q1, Q2], 0, beta, pp)
      const resDecom = await ecLib.toAffine(resJac[0], resJac[1], resJac[2], pp)

      // non-decomp mul
      const kPoint = await ecLib.ecMul(k, P1, P2, 0, pp)
      const lPoint = await ecLib.ecMul(l, Q1, Q2, 0, pp)
      const res = await ecLib.ecAdd(lPoint[0], lPoint[1], kPoint[0], kPoint[1], 0, pp)

      // assert same result
      const mulX = resDecom[0]
      const mulY = resDecom[1]
      assert(resDecom[0].eq(res[0]))
      assert(resDecom[1].eq(res[1]))
      const expectedMulX = web3.utils.toBN("0x5CBDF0646E5DB4EAA398F365F2EA7A0E3D419B7E0330E39CE92BDDEDCAC4F9BC")
      const expectedMulY = web3.utils.toBN("0x951435BF45DAA69F5CE8729279E5AB2457EC2F47EC02184A5AF7D9D6F78D9755")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulY.toString(10), expectedMulY.toString())
    })
    it("Should test scalar decomposition multiplication 3", async () => {
      const k = web3.utils.toBN("115792089237316195423570985008687907852837564279074904382605163141518161494329")
      const kDecom = await ecLib.scalarDecomposition(k, n, lambda)
      const l = web3.utils.toBN("5")
      const lDecom = await ecLib.scalarDecomposition(l, n, lambda)
      //const l1 = web3.utils.toBN("5")
      //const l2 = web3.utils.toBN("0")
      const P1 = web3.utils.toBN("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
      const P2 = web3.utils.toBN("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
      const Q1 = web3.utils.toBN("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
      const Q2 = web3.utils.toBN("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
      const resJac = await ecLib._sim_mul([kDecom[0], kDecom[1], lDecom[0], lDecom[1]], [P1, P2, Q1, Q2], 0, beta, pp)
      const res_affine = await ecLib.toAffine(resJac[0], resJac[1], resJac[2], pp)
      // non decomposed mul
      const kPoint = await ecLib.ecMul(k, P1, P2, 0, pp)
      const lPoint = await ecLib.ecMul(5, P1, P2, 0, pp)
      const res = await ecLib.ecAdd(lPoint[0], lPoint[1], kPoint[0], kPoint[1], 0, pp)
      const mulX = res_affine[0]
      const mulY = res_affine[1]
      assert(res_affine[0].eq(res[0]))
      assert(res_affine[1].eq(res[1]))
      const expectedMulX = web3.utils.toBN("0xF9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9")
      const expectedMulY = web3.utils.toBN("0xC77084F09CD217EBF01CC819D5C80CA99AFF5666CB3DDCE4934602897B4715BD")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulY.toString(10), expectedMulY.toString())
    })
    it("Should test scalar decomposition multiplication 4", async () => {
      //const k1 = web3.utils.toBN("-75853609866811635898812693916901439793")
      //const k2 = web3.utils.toBN("-91979353254113275055958955257284867062")
      const k = web3.utils.toBN("28948022309329048855892746252171976963209391069768726095651290785379540373584")
      const kDecom = await ecLib.scalarDecomposition(k, n, lambda)
      //const l1 = web3.utils.toBN("216210193282829828426210433195336588662")
      //const l2 = web3.utils.toBN("-119455732959019993483332865153036025047")
      const l = web3.utils.toBN("57896044618658097711785492504343953926418782139537452191302581570759080747168")
      const lDecom = await ecLib.scalarDecomposition(l, n, lambda)
      const P1 = web3.utils.toBN("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
      const P2 = web3.utils.toBN("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
      const Q1 = web3.utils.toBN("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
      const Q2 = web3.utils.toBN("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
      const resJac = await ecLib._sim_mul([kDecom[0], kDecom[1], lDecom[0], lDecom[1]], [P1, P2, Q1, Q2], 0, beta, pp)
      const res_affine = await ecLib.toAffine(resJac[0], resJac[1], resJac[2], pp)
      // non decomposed mul
      const kPoint = await ecLib.ecMul(k, P1, P2, 0, pp)
      const lPoint = await ecLib.ecMul(l, P1, P2, 0, pp)
      const res = await ecLib.ecAdd(lPoint[0], lPoint[1], kPoint[0], kPoint[1], 0, pp)
      const mulX = res_affine[0]
      const mulY = res_affine[1]
      assert(res_affine[0].eq(res[0]))
      assert(res_affine[1].eq(res[1]))
      const expectedMulX = web3.utils.toBN("0xE24CE4BEEE294AA6350FAA67512B99D388693AE4E7F53D19882A6EA169FC1CE1")
      const expectedMulY = web3.utils.toBN("0x8B71E83545FC2B5872589F99D948C03108D36797C4DE363EBD3FF6A9E1A95B10")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulY.toString(10), expectedMulY.toString())
    })
    it("Should test scalar decomposition multiplication 6", async () => {
      const k = web3.utils.toBN("28948022309329048855892746252171976963209391069768726095651290785379540373584")
      const kDecom = await ecLib.scalarDecomposition(k, n, lambda)
      const l = web3.utils.toBN("57896044618658097711785492504343953926418782139537452191302581570759080747168")
      const lDecom = await ecLib.scalarDecomposition(l, n, lambda)
      const P1 = web3.utils.toBN("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
      const P2 = web3.utils.toBN("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
      const Q1 = web3.utils.toBN("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
      const Q2 = web3.utils.toBN("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
      const resJac = await ecLib._sim_mul([kDecom[0], kDecom[1], lDecom[0], lDecom[1]], [P1, P2, Q1, Q2], 0, beta, pp)
      const res_affine = await ecLib.toAffine(resJac[0], resJac[1], resJac[2], pp)
      // non decomposed mul
      const kPoint = await ecLib.ecMul(k, P1, P2, 0, pp)
      const lPoint = await ecLib.ecMul(l, P1, P2, 0, pp)
      const res = await ecLib.ecAdd(lPoint[0], lPoint[1], kPoint[0], kPoint[1], 0, pp)
      const mulX = res_affine[0]
      const mulY = res_affine[1]
      assert(res_affine[0].eq(res[0]))
      assert(res_affine[1].eq(res[1]))
      const expectedMulX = web3.utils.toBN("0xE24CE4BEEE294AA6350FAA67512B99D388693AE4E7F53D19882A6EA169FC1CE1")
      const expectedMulY = web3.utils.toBN("0x8B71E83545FC2B5872589F99D948C03108D36797C4DE363EBD3FF6A9E1A95B10")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulY.toString(10), expectedMulY.toString())
    })
  })
  describe("secp256r1", () => {
    const gx = web3.utils.toBN("0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296")
    const gy = web3.utils.toBN("0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5")
    const pp = web3.utils.toBN("FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF")
    const a = web3.utils.toBN("FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC")
    const b = web3.utils.toBN("5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B")

    let ecLib
    before(async () => {
      ecLib = await EllipticCurve.deployed()
    })
    it("Should convert a Jacobian point to affine", async () => {
      var x = web3.utils.toBN("0x88E6BB871813A28C4E9AFDCD94B79D85DE4794A3C4695B311FB3C7EF1CECE619")
      var y = web3.utils.toBN("0x3D709DD3A0B3293201BCEE8E02249399DB3C130F2642C8F954417DC639ADDD22")
      var z = web3.utils.toBN("0xEEEAA21B71DA080527B358D3EE861B774FB5BCC79D304533C096F3A44F0E7A2")

      const affine = await ecLib.toAffine(x, y, z, pp)
      var expectedX = web3.utils.toBN("0xE2534A3532D08FBBA02DDE659EE62BD0031FE2DB785596EF509302446B030852")
      var expectedY = web3.utils.toBN("0xE0F1575A4C633CC719DFEE5FDA862D764EFC96C3F30EE0055C42C23F184ED8C6")

      assert.equal(affine[0].toString(), expectedX.toString())
      assert.equal(affine[1].toString(), expectedY.toString())
    })
    it("Invalid numbers", async () => {
      var d = new BN(0)
      try {
        // eslint-disable-next-line
        const inv = await ecLib.invMod(d, pp)
      } catch (error) {
        assert(error, "Invalid number")
      }
      try {
        // eslint-disable-next-line
        const inv = await ecLib.invMod(pp, d)
      } catch (error) {
        assert(error, "Invalid number")
      }
      try {
        // eslint-disable-next-line
        const inv = await ecLib.invMod(pp, pp)
      } catch (error) {
        assert(error, "Invalid number")
      }
    })
    it("Inverse of 1", async () => {
      var d = new BN(1)
      const inv = await ecLib.invMod(d, pp)
      assert.equal(inv.toString(10), "1")
    })
    it("Should Invert an inverted number and be the same", async () => {
      const y1 = web3.utils.toBN("0x9d42bf0c35d765c2242712205e8f8b1ea588f470a6980b21bc9efb4ab33ae246")
      const inverted = await ecLib.invMod(y1, pp)
      const newY1 = await ecLib.invMod(inverted, pp)
      assert.equal(newY1.toString(), y1.toString())
    })
    it("Should get the y coordinate based on parity", async () => {
      const x = gx
      const y = await ecLib.deriveY(0x03, x, a, b, pp)
      assert.equal(gy.toString(), y.toString())
    })
    it("Should identify if point is on the curve", async () => {
      const x = gx
      const y = gy
      assert.equal(await ecLib.isOnCurve(x, y, a, b, pp), true)
    })
    it("Should identify if point is NOT on the curve", async () => {
      const x = web3.utils.toBN("0x6B17D1F3E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296")
      const y = web3.utils.toBN("0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5")
      assert.equal(await ecLib.isOnCurve(x, y, a, b, pp), false)
    })
    it("Should Add two big numbers", async () => {
      const x1 = gx
      const z1 = gy
      const x2 = web3.utils.toBN("0x5ECBE4D1A6330A44C8F7EF951D4BF165E6C6B721EFADA985FB41661BC6E7FD6C")
      const z2 = web3.utils.toBN("0x8734640C4998FF7E374B06CE1A64A2ECD82AB036384FB83D9A79B127A27D5032")
      const res = await ecLib.ecAdd(x1, z1, x2, z2, a, pp)
      const sumX = res[0]
      const sumZ = res[1]
      const expectedSumX = web3.utils.toBN("0xE2534A3532D08FBBA02DDE659EE62BD0031FE2DB785596EF509302446B030852")
      const expectedSumZ = web3.utils.toBN("0xE0F1575A4C633CC719DFEE5FDA862D764EFC96C3F30EE0055C42C23F184ED8C6")
      assert.equal(sumX.toString(10), expectedSumX.toString())
      assert.equal(sumZ.toString(10), expectedSumZ.toString())
    })
    it("Should Invert an ec point", async () => {
      const x = web3.utils.toBN("0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978")
      const y = web3.utils.toBN("0x7775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1")
      const invertedPoint = await ecLib.ecInv(x, y, pp)

      const expectedY = web3.utils.toBN("0xF888AAEE24712FC0D6C26539608BCF244582521AC3167DD661FB4862DD878C2E")
      assert.equal(invertedPoint[0].toString(), x.toString())
      assert.equal(invertedPoint[1].toString(), expectedY.toString())
    })
    it("Should Sub two big numbers", async () => {
      const x1 = web3.utils.toBN("0x5ECBE4D1A6330A44C8F7EF951D4BF165E6C6B721EFADA985FB41661BC6E7FD6C")
      const z1 = web3.utils.toBN("0x8734640C4998FF7E374B06CE1A64A2ECD82AB036384FB83D9A79B127A27D5032")
      const x2 = gx
      const z2 = gy
      const res = await ecLib.ecSub(x1, z1, x2, z2, a, pp)
      const sumX = res[0]
      const sumZ = res[1]
      const expectedSubX = web3.utils.toBN("0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978")
      const expectedSubY = web3.utils.toBN("0x7775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1")
      assert.equal(sumX.toString(10), expectedSubX.toString())
      assert.equal(sumZ.toString(10), expectedSubY.toString())
    })
    it("Should double EcPoint", async () => {
      const x1 = web3.utils.toBN("0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978")
      const y1 = web3.utils.toBN("0x7775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1")
      const res = await ecLib.ecAdd(x1, y1, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0xE2534A3532D08FBBA02DDE659EE62BD0031FE2DB785596EF509302446B030852")
      const expectedMulY = web3.utils.toBN("0xE0F1575A4C633CC719DFEE5FDA862D764EFC96C3F30EE0055C42C23F184ED8C6")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should Add two big numbers", async () => {
      const x1 = web3.utils.toBN("0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296")
      const z1 = web3.utils.toBN("0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5")
      const res = await ecLib.ecAdd(x1, z1, 0, 0, a, pp)
      const sumX = res[0]
      const sumZ = res[1]
      assert.equal(sumX.toString(10), x1.toString())
      assert.equal(sumZ.toString(10), z1.toString())
    })
    it("Should multiply x2 EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x02")
      const res = await ecLib.ecMul(d, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978")
      const expectedMulY = web3.utils.toBN("0x7775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should multiply x EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x03")
      const res = await ecLib.ecMul(d, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0x5ECBE4D1A6330A44C8F7EF951D4BF165E6C6B721EFADA985FB41661BC6E7FD6C")
      const expectedMulY = web3.utils.toBN("0x8734640C4998FF7E374B06CE1A64A2ECD82AB036384FB83D9A79B127A27D5032")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    
    })
    it("Should multiply small scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const res = await ecLib.ecMul(0x04, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0xE2534A3532D08FBBA02DDE659EE62BD0031FE2DB785596EF509302446B030852")
      const expectedMulY = web3.utils.toBN("0xE0F1575A4C633CC719DFEE5FDA862D764EFC96C3F30EE0055C42C23F184ED8C6")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should multiply big scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x159D893D4CDD747246CDCA43590E13")
      const res = await ecLib.ecMul(d, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0x1B7E046A076CC25E6D7FA5003F6729F665CC3241B5ADAB12B498CD32F2803264")
      const expectedMulY = web3.utils.toBN("0xBFEA79BE2B666B073DB69A2A241ADAB0738FE9D2DD28B5604EB8C8CF097C457B")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
  })
  describe("secp192r1", () => {
    const gx = web3.utils.toBN("0x188DA80EB03090F67CBF20EB43A18800F4FF0AFD82FF1012")
    const gy = web3.utils.toBN("0x7192B95FFC8DA78631011ED6B24CDD573F977A11E794811")
    const pp = web3.utils.toBN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFF")
    const a = web3.utils.toBN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFC")
    const b = web3.utils.toBN("64210519E59C80E70FA7E9AB72243049FEB8DEECC146B9B1")

    let ecLib
    before(async () => {
      ecLib = await EllipticCurve.deployed()
    })
    it("Should get the y coordinate based on parity", async () => {
      const x = gx
      const y = await ecLib.deriveY(0x03, x, a, b, pp)
      assert.equal(gy.toString(), y.toString())
    })
    it("Should Add two big numbers", async () => {
      const x1 = gx
      const z1 = gy
      const x2 = web3.utils.toBN("0xDAFEBF5828783F2AD35534631588A3F629A70FB16982A888")
      const z2 = web3.utils.toBN("0xDD6BDA0D993DA0FA46B27BBC141B868F59331AFA5C7E93AB")
      const res = await ecLib.ecAdd(x1, z1, x2, z2, a, pp)
      const sumX = res[0]
      const sumZ = res[1]
      const expectedSumX = web3.utils.toBN("0x76E32A2557599E6EDCD283201FB2B9AADFD0D359CBB263DA")
      const expectedSumZ = web3.utils.toBN("0x782C37E372BA4520AA62E0FED121D49EF3B543660CFD05FD")
      assert.equal(sumX.toString(10), expectedSumX.toString())
      assert.equal(sumZ.toString(10), expectedSumZ.toString())
    })
    it("Should Sub two big numbers", async () => {
      const x1 = web3.utils.toBN("0x10BB8E9840049B183E078D9C300E1605590118EBDD7FF590")
      const z1 = web3.utils.toBN("0x31361008476F917BADC9F836E62762BE312B72543CCEAEA1")
      const x2 = web3.utils.toBN("0x76E32A2557599E6EDCD283201FB2B9AADFD0D359CBB263DA")
      const z2 = web3.utils.toBN("0x782C37E372BA4520AA62E0FED121D49EF3B543660CFD05FD")
      const res = await ecLib.ecSub(x1, z1, x2, z2, a, pp)
      const sumX = res[0]
      const sumZ = res[1]
      const expectedSubX = web3.utils.toBN("0xDAFEBF5828783F2AD35534631588A3F629A70FB16982A888")
      const expectedSubY = web3.utils.toBN("0xDD6BDA0D993DA0FA46B27BBC141B868F59331AFA5C7E93AB")
      assert.equal(sumX.toString(10), expectedSubX.toString())
      assert.equal(sumZ.toString(10), expectedSubY.toString())
    })
    it("Should double EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const res = await ecLib.ecAdd(x1, y1, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0xDAFEBF5828783F2AD35534631588A3F629A70FB16982A888")
      const expectedMulY = web3.utils.toBN("0xDD6BDA0D993DA0FA46B27BBC141B868F59331AFA5C7E93AB")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should Add two big numbers", async () => {
      const x1 = gx
      const z1 = gy
      const res = await ecLib.ecAdd(x1, z1, 0, 0, a, pp)
      const sumX = res[0]
      const sumZ = res[1]
      assert.equal(sumX.toString(10), x1.toString())
      assert.equal(sumZ.toString(10), z1.toString())
    })
    it("Should multiply x2 EcPoint", async () => {
      const x1 = web3.utils.toBN("0xDAFEBF5828783F2AD35534631588A3F629A70FB16982A888")
      const y1 = web3.utils.toBN("0xDD6BDA0D993DA0FA46B27BBC141B868F59331AFA5C7E93AB")
      const d = web3.utils.toBN("0x02")
      const res = await ecLib.ecMul(d, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0x35433907297CC378B0015703374729D7A4FE46647084E4BA")
      const expectedMulY = web3.utils.toBN("0xA2649984F2135C301EA3ACB0776CD4F125389B311DB3BE32")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should multiply x EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x03")
      const res = await ecLib.ecMul(d, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0x76E32A2557599E6EDCD283201FB2B9AADFD0D359CBB263DA")
      const expectedMulY = web3.utils.toBN("0x782C37E372BA4520AA62E0FED121D49EF3B543660CFD05FD")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should multiply small scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const res = await ecLib.ecMul(0x04, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0x35433907297CC378B0015703374729D7A4FE46647084E4BA")
      const expectedMulY = web3.utils.toBN("0xA2649984F2135C301EA3ACB0776CD4F125389B311DB3BE32")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should multiply big scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x159D893D4CDD747246CDCA43590E13")
      const res = await ecLib.ecMul(d, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0xB357B10AC985C891B29FB37DA56661CCCF50CEC21128D4F6")
      const expectedMulY = web3.utils.toBN("0xBA20DC2FA1CC228D3C2D8B538C2177C2921884C6B7F0D96F")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
  })
  describe("secp224r1", () => {
    const gx = web3.utils.toBN("0xB70E0CBD6BB4BF7F321390B94A03C1D356C21122343280D6115C1D21")
    const gy = web3.utils.toBN("0xBD376388B5F723FB4C22DFE6CD4375A05A07476444D5819985007E34")
    const pp = web3.utils.toBN("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000001")
    const a = web3.utils.toBN("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFE")
    let ecLib
    before(async () => {
      ecLib = await EllipticCurve.deployed()
    })
    it("Should Add two big numbers", async () => {
      const x1 = gx
      const z1 = gy
      const x2 = web3.utils.toBN("0x706A46DC76DCB76798E60E6D89474788D16DC18032D268FD1A704FA6")
      const z2 = web3.utils.toBN("0x1C2B76A7BC25E7702A704FA986892849FCA629487ACF3709D2E4E8BB")
      const res = await ecLib.ecAdd(x1, z1, x2, z2, a, pp)
      const sumX = res[0]
      const sumZ = res[1]
      const expectedSumX = web3.utils.toBN("0xDF1B1D66A551D0D31EFF822558B9D2CC75C2180279FE0D08FD896D04")
      const expectedSumZ = web3.utils.toBN("0xA3F7F03CADD0BE444C0AA56830130DDF77D317344E1AF3591981A925")
      assert.equal(sumX.toString(10), expectedSumX.toString())
      assert.equal(sumZ.toString(10), expectedSumZ.toString())
    })
    it("Should Sub two big numbers", async () => {
      const x1 = web3.utils.toBN("0x31C49AE75BCE7807CDFF22055D94EE9021FEDBB5AB51C57526F011AA")
      const z1 = web3.utils.toBN("0x27E8BFF1745635EC5BA0C9F1C2EDE15414C6507D29FFE37E790A079B")
      const x2 = web3.utils.toBN("0xDF1B1D66A551D0D31EFF822558B9D2CC75C2180279FE0D08FD896D04")
      const z2 = web3.utils.toBN("0xA3F7F03CADD0BE444C0AA56830130DDF77D317344E1AF3591981A925")
      const res = await ecLib.ecSub(x1, z1, x2, z2, a, pp)
      const sumX = res[0]
      const sumZ = res[1]
      const expectedSubX = web3.utils.toBN("0x706A46DC76DCB76798E60E6D89474788D16DC18032D268FD1A704FA6")
      const expectedSubY = web3.utils.toBN("0x1C2B76A7BC25E7702A704FA986892849FCA629487ACF3709D2E4E8BB")
      assert.equal(sumX.toString(10), expectedSubX.toString())
      assert.equal(sumZ.toString(10), expectedSubY.toString())
    })
    it("Should double EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const res = await ecLib.ecAdd(x1, y1, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0x706A46DC76DCB76798E60E6D89474788D16DC18032D268FD1A704FA6")
      const expectedMulY = web3.utils.toBN("0x1C2B76A7BC25E7702A704FA986892849FCA629487ACF3709D2E4E8BB")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should Add two big numbers", async () => {
      const x1 = gx
      const z1 = gx
      const res = await ecLib.ecAdd(x1, z1, 0, 0, a, pp)
      const sumX = res[0]
      const sumZ = res[1]
      assert.equal(sumX.toString(10), x1.toString())
      assert.equal(sumZ.toString(10), z1.toString())
    })
    it("Should multiply x2 EcPoint", async () => {
      const x1 = web3.utils.toBN("0x706A46DC76DCB76798E60E6D89474788D16DC18032D268FD1A704FA6")
      const y1 = web3.utils.toBN("0x1C2B76A7BC25E7702A704FA986892849FCA629487ACF3709D2E4E8BB")
      const d = web3.utils.toBN("0x02")
      const res = await ecLib.ecMul(d, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0xAE99FEEBB5D26945B54892092A8AEE02912930FA41CD114E40447301")
      const expectedMulY = web3.utils.toBN("0x482580A0EC5BC47E88BC8C378632CD196CB3FA058A7114EB03054C9")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should multiply x EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x03")
      const res = await ecLib.ecMul(d, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0xDF1B1D66A551D0D31EFF822558B9D2CC75C2180279FE0D08FD896D04")
      const expectedMulY = web3.utils.toBN("0xA3F7F03CADD0BE444C0AA56830130DDF77D317344E1AF3591981A925")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should multiply small scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const res = await ecLib.ecMul(0x04, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0xAE99FEEBB5D26945B54892092A8AEE02912930FA41CD114E40447301")
      const expectedMulY = web3.utils.toBN("0x482580A0EC5BC47E88BC8C378632CD196CB3FA058A7114EB03054C9")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
    it("Should multiply big scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x159D893D4CDD747246CDCA43590E13")
      const res = await ecLib.ecMul(d, x1, y1, a, pp)
      const mulX = res[0]
      const mulZ = res[1]
      const expectedMulX = web3.utils.toBN("0x29895F0AF496BFC62B6EF8D8A65C88C613949B03668AAB4F0429E35")
      const expectedMulY = web3.utils.toBN("0x3EA6E53F9A841F2019EC24BDE1A75677AA9B5902E61081C01064DE93")
      assert.equal(mulX.toString(10), expectedMulX.toString())
      assert.equal(mulZ.toString(10), expectedMulY.toString())
    })
  })
})
