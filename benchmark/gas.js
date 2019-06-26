const BN = web3.utils.BN
const EllipticCurve = artifacts.require("./EllipticCurve")

contract("EllipticCurve", accounts => {
  describe("secp256k1", () => {
    const gx = web3.utils.toBN("79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
    const gy = web3.utils.toBN("483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8")
    const pp = web3.utils.toBN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F")
    let ecLib
    before(async () => {
      ecLib = await EllipticCurve.deployed()
    })
    it("Should convert a Jacobian point to affine", async () => {
      var x = web3.utils.toBN("0x7D152C041EA8E1DC2191843D1FA9DB55B68F88FEF695E2C791D40444B365AFC2")
      var y = web3.utils.toBN("0x56915849F52CC8F76F5FD7E4BF60DB4A43BF633E1B1383F85FE89164BFADCBDB")
      var z = web3.utils.toBN("0x9075B4EE4D4788CABB49F7F81C221151FA2F68914D0AA833388FA11FF621A970")
      await ecLib.toAffine(x, y, z, pp)
    })
    it("Invalid numbers", async () => {
      var d = new BN(0)
      try {
        // eslint-disable-next-line
        await ecLib.invMod(d, pp)
      } catch (error) {
      }
      try {
        // eslint-disable-next-line
        await ecLib.invMod(pp, d)
      } catch (error) {
      }
      try {
        // eslint-disable-next-line
        await ecLib.invMod(pp, pp)
      } catch (error) {
      }
    })
    it("Inverse of 1", async () => {
      var d = new BN(1)
      await ecLib.invMod(d, pp)
    })
    it("Should Invert an inverted number and be the same", async () => {
      const y1 = web3.utils.toBN("0x9d42bf0c35d765c2242712205e8f8b1ea588f470a6980b21bc9efb4ab33ae246")
      await ecLib.invMod(y1, pp)
    })
    it("Should get the y coordinate based on parity", async () => {
      const coordX = "0xc2704fed5dc41d3979235b85edda8f86f1806c17ce0a516a034c605d2b4f9a26"
      await ecLib.deriveY(0x03, web3.utils.hexToBytes(coordX), 0, 7, pp)
    })
    it("Should identify if point is on the curve", async () => {
      const x = web3.utils.toBN("0xe906a3b4379ddbff598994b2ff026766fb66424710776099b85111f23f8eebcc")
      const y = web3.utils.toBN("0x7638965bf85f5f2b6641324389ef2ffb99576ba72ec19d8411a5ea1dd251b112")
      await ecLib.isOnCurve(x, y, 0, 7, pp)
    })
    it("Should identify if point is NOT on the curve", async () => {
      const x = web3.utils.toBN("0x3bf754f48bc7c5fb077736c7d2abe85354be649caa94971f907b3a81759e5b5e")
      const y = web3.utils.toBN("0x6b936ce0a2a40016bbb2eb0a4a1347b5af76a41d44b56dec26108269a45bce78")
      await ecLib.isOnCurve(x, y, 0, 7, pp)
    })
    it("Should Add two big numbers", async () => {
      const x1 = web3.utils.toBN("0x3596f1f475c8999ffe35ccf7cebee7373ee40513ad467e3fc38600aa06d41bcf")
      const z1 = web3.utils.toBN("0x825a3eb4f09a55637391c950ba5e25c1ea658a15f234c14ebec79e5c68bd4133")
      const x2 = web3.utils.toBN("0x1c2a90c4c30f60e878d1fe317acf4f2e059300e3deaa1c949628096ecaf993b2")
      const z2 = web3.utils.toBN("0x62bd40f3ca289a3ddbd8eddfa17074e15a770b8f5967f4de436104b44cc519e9")
      await ecLib.ecAdd(x1, z1, x2, z2, 0, pp)
    })
    it("Should Invert an ec point", async () => {
      const x = web3.utils.toBN("0x1c2a90c4c30f60e878d1fe317acf4f2e059300e3deaa1c949628096ecaf993b2")
      const y = web3.utils.toBN("0x9d42bf0c35d765c2242712205e8f8b1ea588f470a6980b21bc9efb4ab33ae246")
      await ecLib.ecInv(x, y, pp)
    })
    it("Should Sub two big numbers", async () => {
      const x1 = web3.utils.toBN("0x3596f1f475c8999ffe35ccf7cebee7373ee40513ad467e3fc38600aa06d41bcf")
      const z1 = web3.utils.toBN("0x825a3eb4f09a55637391c950ba5e25c1ea658a15f234c14ebec79e5c68bd4133")
      const x2 = web3.utils.toBN("0x1c2a90c4c30f60e878d1fe317acf4f2e059300e3deaa1c949628096ecaf993b2")
      const z2 = web3.utils.toBN("0x9d42bf0c35d765c2242712205e8f8b1ea588f470a6980b21bc9efb4ab33ae246")
      await ecLib.ecSub(x1, z1, x2, z2, 0, pp)
    })
    it("Should double EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      await ecLib.ecAdd(x1, y1, x1, y1, 0, pp)
    })
    it("Should Add two big numbers", async () => {
      const x1 = web3.utils.toBN("0xC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5")
      const z1 = web3.utils.toBN("0x1AE168FEA63DC339A3C58419466CEAEEF7F632653266D0E1236431A950CFE52A")
      await ecLib.ecAdd(x1, z1, 0, 0, 0, pp)
    })
    it("Should multiply x2 EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x02")
      await ecLib.ecMul(d, x1, y1, 0, pp)
    })
    it("Should multiply big scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140")
      await ecLib.ecMul(d, x1, y1, 0, pp)
    })
    it("Should multiply small scalar with EcPoint", async () => {
      const x1 = web3.utils.toBN("0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
      const y1 = web3.utils.toBN("0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8")
      const d = web3.utils.toBN("0x05")
      await ecLib.ecMul(d, x1, y1, 0, pp)
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

      await ecLib.toAffine(x, y, z, pp)
    })
    it("Invalid numbers", async () => {
      var d = new BN(0)
      try {
        // eslint-disable-next-line
        await ecLib.invMod(d, pp)
      } catch (error) {
        assert(error, "Invalid number")
      }
      try {
        // eslint-disable-next-line
        await ecLib.invMod(pp, d)
      } catch (error) {
        assert(error, "Invalid number")
      }
      try {
        // eslint-disable-next-line
        await ecLib.invMod(pp, pp)
      } catch (error) {
        assert(error, "Invalid number")
      }
    })
    it("Inverse of 1", async () => {
      var d = new BN(1)
      await ecLib.invMod(d, pp)
    })
    it("Should Invert an inverted number and be the same", async () => {
      const y1 = web3.utils.toBN("0x9d42bf0c35d765c2242712205e8f8b1ea588f470a6980b21bc9efb4ab33ae246")
      await ecLib.invMod(y1, pp)
    })
    it("Should get the y coordinate based on parity", async () => {
      const x = gx
      await ecLib.deriveY(0x03, x, a, b, pp)
    })
    it("Should identify if point is on the curve", async () => {
      const x = gx
      const y = gy
      await ecLib.isOnCurve(x, y, a, b, pp)
    })
    it("Should identify if point is NOT on the curve", async () => {
      const x = web3.utils.toBN("0x6B17D1F3E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296")
      const y = web3.utils.toBN("0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5")
      await ecLib.isOnCurve(x, y, a, b, pp)
    })
    it("Should Add two big numbers", async () => {
      const x1 = gx
      const z1 = gy
      const x2 = web3.utils.toBN("0x5ECBE4D1A6330A44C8F7EF951D4BF165E6C6B721EFADA985FB41661BC6E7FD6C")
      const z2 = web3.utils.toBN("0x8734640C4998FF7E374B06CE1A64A2ECD82AB036384FB83D9A79B127A27D5032")
      await ecLib.ecAdd(x1, z1, x2, z2, a, pp)
    })
    it("Should Invert an ec point", async () => {
      const x = web3.utils.toBN("0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978")
      const y = web3.utils.toBN("0x7775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1")
      await ecLib.ecInv(x, y, pp)
    })
    it("Should Sub two big numbers", async () => {
      const x1 = web3.utils.toBN("0x5ECBE4D1A6330A44C8F7EF951D4BF165E6C6B721EFADA985FB41661BC6E7FD6C")
      const z1 = web3.utils.toBN("0x8734640C4998FF7E374B06CE1A64A2ECD82AB036384FB83D9A79B127A27D5032")
      const x2 = gx
      const z2 = gy
      await ecLib.ecSub(x1, z1, x2, z2, a, pp)
    })
    it("Should double EcPoint", async () => {
      const x1 = web3.utils.toBN("0x7CF27B188D034F7E8A52380304B51AC3C08969E277F21B35A60B48FC47669978")
      const y1 = web3.utils.toBN("0x7775510DB8ED040293D9AC69F7430DBBA7DADE63CE982299E04B79D227873D1")
      await ecLib.ecAdd(x1, y1, x1, y1, a, pp)
    })
    it("Should Add two big numbers", async () => {
      const x1 = web3.utils.toBN("0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296")
      const z1 = web3.utils.toBN("0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5")
      await ecLib.ecAdd(x1, z1, 0, 0, a, pp)
    })
    it("Should multiply x2 EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x02")
      await ecLib.ecMul(d, x1, y1, a, pp)
    })
    it("Should multiply x EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x03")
      await ecLib.ecMul(d, x1, y1, a, pp)
    })
    it("Should multiply small scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      await ecLib.ecMul(0x04, x1, y1, a, pp)
    })
    it("Should multiply big scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x159D893D4CDD747246CDCA43590E13")
      await ecLib.ecMul(d, x1, y1, a, pp)
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
      await ecLib.deriveY(0x03, x, a, b, pp)
    })
    it("Should Add two big numbers", async () => {
      const x1 = gx
      const z1 = gy
      const x2 = web3.utils.toBN("0xDAFEBF5828783F2AD35534631588A3F629A70FB16982A888")
      const z2 = web3.utils.toBN("0xDD6BDA0D993DA0FA46B27BBC141B868F59331AFA5C7E93AB")
      await ecLib.ecAdd(x1, z1, x2, z2, a, pp)
    })
    it("Should Sub two big numbers", async () => {
      const x1 = web3.utils.toBN("0x10BB8E9840049B183E078D9C300E1605590118EBDD7FF590")
      const z1 = web3.utils.toBN("0x31361008476F917BADC9F836E62762BE312B72543CCEAEA1")
      const x2 = web3.utils.toBN("0x76E32A2557599E6EDCD283201FB2B9AADFD0D359CBB263DA")
      const z2 = web3.utils.toBN("0x782C37E372BA4520AA62E0FED121D49EF3B543660CFD05FD")
      await ecLib.ecSub(x1, z1, x2, z2, a, pp)
    })
    it("Should double EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      await ecLib.ecAdd(x1, y1, x1, y1, a, pp)
    })
    it("Should Add two big numbers", async () => {
      const x1 = gx
      const z1 = gy
      await ecLib.ecAdd(x1, z1, 0, 0, a, pp)
    })
    it("Should multiply x2 EcPoint", async () => {
      const x1 = web3.utils.toBN("0xDAFEBF5828783F2AD35534631588A3F629A70FB16982A888")
      const y1 = web3.utils.toBN("0xDD6BDA0D993DA0FA46B27BBC141B868F59331AFA5C7E93AB")
      const d = web3.utils.toBN("0x02")
      await ecLib.ecMul(d, x1, y1, a, pp)
    })
    it("Should multiply x EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x03")
      await ecLib.ecMul(d, x1, y1, a, pp)
    })
    it("Should multiply small scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      await ecLib.ecMul(0x04, x1, y1, a, pp)
    })
    it("Should multiply big scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x159D893D4CDD747246CDCA43590E13")
      await ecLib.ecMul(d, x1, y1, a, pp)
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
      await ecLib.ecAdd(x1, z1, x2, z2, a, pp)
    })
    it("Should Sub two big numbers", async () => {
      const x1 = web3.utils.toBN("0x31C49AE75BCE7807CDFF22055D94EE9021FEDBB5AB51C57526F011AA")
      const z1 = web3.utils.toBN("0x27E8BFF1745635EC5BA0C9F1C2EDE15414C6507D29FFE37E790A079B")
      const x2 = web3.utils.toBN("0xDF1B1D66A551D0D31EFF822558B9D2CC75C2180279FE0D08FD896D04")
      const z2 = web3.utils.toBN("0xA3F7F03CADD0BE444C0AA56830130DDF77D317344E1AF3591981A925")
      await ecLib.ecSub(x1, z1, x2, z2, a, pp)
    })
    it("Should double EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      await ecLib.ecAdd(x1, y1, x1, y1, a, pp)
    })
    it("Should Add two big numbers", async () => {
      const x1 = gx
      const z1 = gx
      await ecLib.ecAdd(x1, z1, 0, 0, a, pp)
    })
    it("Should multiply x2 EcPoint", async () => {
      const x1 = web3.utils.toBN("0x706A46DC76DCB76798E60E6D89474788D16DC18032D268FD1A704FA6")
      const y1 = web3.utils.toBN("0x1C2B76A7BC25E7702A704FA986892849FCA629487ACF3709D2E4E8BB")
      const d = web3.utils.toBN("0x02")
      await ecLib.ecMul(d, x1, y1, a, pp)
    })
    it("Should multiply x EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x03")
      await ecLib.ecMul(d, x1, y1, a, pp)
    })
    it("Should multiply small scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      await ecLib.ecMul(0x04, x1, y1, a, pp)
    })
    it("Should multiply big scalar with EcPoint", async () => {
      const x1 = gx
      const y1 = gy
      const d = web3.utils.toBN("0x159D893D4CDD747246CDCA43590E13")
      await ecLib.ecMul(d, x1, y1, a, pp)
    })
  })
})
