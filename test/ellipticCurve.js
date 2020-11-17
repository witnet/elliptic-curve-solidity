const EllipticCurve = artifacts.require("./TestEllipticCurve")

contract("EllipticCurve", accounts => {
  // /////////////////////////////////////////// //
  // Check auxiliary operations for given curves //
  // /////////////////////////////////////////// //
  const auxCurves = ["secp256k1", "P256"]

  for (const curve of auxCurves) {
    describe(`Aux. operations - Curve ${curve}`, () => {
      const curveData = require(`./data/${curve}-aux.json`)

      const pp = web3.utils.toBN(curveData.params.pp)
      const aa = web3.utils.toBN(curveData.params.aa)
      const bb = web3.utils.toBN(curveData.params.bb)

      let ecLib
      before(async () => {
        ecLib = await EllipticCurve.new()
      })

      // toAffine
      for (const [index, test] of curveData.toAffine.valid.entries()) {
        it(`should convert a Jacobian point to affine (${index + 1})`, async () => {
          const affine = await ecLib.toAffine.call(
            web3.utils.toBN(test.input.x),
            web3.utils.toBN(test.input.y),
            web3.utils.toBN(test.input.z),
            pp
          )
          const expectedX = web3.utils.toBN(test.output.x)
          const expectedY = web3.utils.toBN(test.output.y)
          assert.equal(affine[0].toString(), expectedX.toString())
          assert.equal(affine[1].toString(), expectedY.toString())
        })
      }

      // invMod
      for (const [index, test] of curveData.invMod.valid.entries()) {
        it(`should invert a scalar (${index + 1}) - ${test.description}`, async () => {
          const inv = await ecLib.invMod.call(
            web3.utils.toBN(test.input.k),
            pp,
          )
          assert.equal(inv.toString(), test.output.k)
        })
      }

      // invMod - invalid inputs
      for (const [index, test] of curveData.invMod.invalid.entries()) {
        it(`should fail when inverting with invalid inputs (${index + 1}) - ${test.description}`, async () => {
          try {
            await ecLib.invMod.call(
              web3.utils.toBN(test.input.k),
              web3.utils.toBN(test.input.mod),
            )
          } catch (error) {
            assert(error, test.output.error)
          }
        })
      }

      // expMod
      for (const [index, test] of curveData.expMod.valid.entries()) {
        it(`should do an expMod with ${test.description} - (${index + 1})`, async () => {
          const exp = await ecLib.expMod.call(
            web3.utils.toBN(test.input.base),
            web3.utils.toBN(test.input.exp),
            pp,
          )
          assert.equal(exp.toString(), test.output.k)
        })
      }

      // deriveY
      for (const [index, test] of curveData.deriveY.valid.entries()) {
        it(`should decode coordinate y from compressed point (${index + 1})`, async () => {
          const coordY = await ecLib.deriveY.call(
            web3.utils.hexToBytes(test.input.sign),
            web3.utils.hexToBytes(test.input.x),
            aa,
            bb,
            pp
          )
          assert.equal(web3.utils.numberToHex(coordY), test.output.y)
        })
      }

      // isOnCurve
      for (const [index, test] of curveData.isOnCurve.valid.entries()) {
        it(`should identify if point is on the curve (${index + 1}) - ${test.output.isOnCurve}`, async () => {
          assert.equal(
            await ecLib.isOnCurve.call(
              web3.utils.hexToBytes(test.input.x),
              web3.utils.hexToBytes(test.input.y),
              aa,
              bb,
              pp),
            test.output.isOnCurve
          )
        })
      }

      // invertPoint
      for (const [index, test] of curveData.invertPoint.valid.entries()) {
        it(`should invert an EC point (${index + 1})`, async () => {
          const invertedPoint = await ecLib.ecInv.call(
            web3.utils.hexToBytes(test.input.x),
            web3.utils.hexToBytes(test.input.y),
            pp
          )
          const expectedX = web3.utils.toBN(test.output.x)
          const expectedY = web3.utils.toBN(test.output.y)
          assert.equal(invertedPoint[0].toString(), expectedX.toString())
          assert.equal(invertedPoint[1].toString(), expectedY.toString())
        })
      }
    })
  }

  // /////////////////////////////////////////////// //
  // Check EC arithmetic operations for given curves //
  // /////////////////////////////////////////////// //
  const curves = ["secp256k1", "secp192k1", "secp224k1", "P256", "P192", "P224"]

  for (const curve of curves) {
    describe(`Arithmetic operations - Curve ${curve}`, () => {
      const curveData = require(`./data/${curve}.json`)

      const pp = web3.utils.toBN(curveData.params.pp)
      const aa = web3.utils.toBN(curveData.params.aa)

      let ecLib
      before(async () => {
        ecLib = await EllipticCurve.new()
      })

      // Addition
      for (const [index, test] of curveData.addition.valid.entries()) {
        it(`should add two numbers (${index + 1}) - ${test.description}`, async () => {
          const res = await ecLib.ecAdd.call(
            web3.utils.toBN(test.input.x1),
            web3.utils.toBN(test.input.y1),
            web3.utils.toBN(test.input.x2),
            web3.utils.toBN(test.input.y2),
            aa,
            pp
          )
          const expectedSumX = web3.utils.toBN(test.output.x)
          const expectedSumZ = web3.utils.toBN(test.output.y)
          assert.equal(res[0].toString(10), expectedSumX.toString())
          assert.equal(res[1].toString(10), expectedSumZ.toString())
        })
      }

      // Subtraction
      for (const [index, test] of curveData.subtraction.valid.entries()) {
        it(`should subtract two numbers (${index + 1}) - ${test.description}`, async () => {
          const res = await ecLib.ecSub.call(
            web3.utils.toBN(test.input.x1),
            web3.utils.toBN(test.input.y1),
            web3.utils.toBN(test.input.x2),
            web3.utils.toBN(test.input.y2),
            aa,
            pp
          )
          const expectedSubX = web3.utils.toBN(test.output.x)
          const expectedSubY = web3.utils.toBN(test.output.y)
          assert.equal(res[0].toString(10), expectedSubX.toString())
          assert.equal(res[1].toString(10), expectedSubY.toString())
        })
      }

      // Multiplication
      for (const [index, test] of curveData.multiplication.valid.entries()) {
        it(`should multiply EC points (${index + 1}) - ${test.description}`, async () => {
          const res = await ecLib.ecMul.call(
            web3.utils.toBN(test.input.k),
            web3.utils.toBN(test.input.x),
            web3.utils.toBN(test.input.y),
            aa,
            pp
          )
          const expectedMulX = web3.utils.toBN(test.output.x)
          const expectedMulY = web3.utils.toBN(test.output.y)
          assert.equal(res[0].toString(10), expectedMulX.toString())
          assert.equal(res[1].toString(10), expectedMulY.toString())
        })
      }
    })
  }
})
