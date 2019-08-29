const EllipticCurve = artifacts.require("./EllipticCurve")

contract("EllipticCurve", accounts => {
  // /////////////////////////////////////////// //
  // Check auxiliary operations for given curves //
  // /////////////////////////////////////////// //
  const auxCurves = ["secp256k1", "P256"]
  for (let curve of auxCurves) {
    describe(`Aux. operations - Curve ${curve}`, () => {
      const curveData = require(`./data/${curve}-aux.json`)

      // const gx = curveData.params.gx
      // const gy = curveData.params.gy
      const pp = web3.utils.toBN(curveData.params.pp)
      // const nn = web3.utils.toBN(curveData.params.nn)
      const aa = web3.utils.toBN(curveData.params.aa)
      const bb = web3.utils.toBN(curveData.params.bb)

      let ecLib
      before(async () => {
        ecLib = await EllipticCurve.deployed()
      })

      // toAffine
      for (let [index, test] of curveData.toAffine.valid.entries()) {
        it(`should convert a Jacobian point to affine (${index + 1})`, async () => {
          const affine = await ecLib.toAffine(
            web3.utils.toBN(test.input.x),
            web3.utils.toBN(test.input.y),
            web3.utils.toBN(test.input.z),
            pp
          )
          var expectedX = web3.utils.toBN(test.output.x)
          var expectedY = web3.utils.toBN(test.output.y)
          assert.equal(affine[0].toString(), expectedX.toString())
          assert.equal(affine[1].toString(), expectedY.toString())
        })
      }

      // invMod
      for (let [index, test] of curveData.invMod.valid.entries()) {
        it(`should invert a scalar (${index + 1}) - ${test.description}`, async () => {
          const inv = await ecLib.invMod(
            web3.utils.toBN(test.input.k),
            pp,
          )
          assert.equal(inv.toString(), test.output.k)
        })
      }

      // invMod - invalid inputs
      for (let [index, test] of curveData.invMod.invalid.entries()) {
        it(`should fail when inverting with invalid inputs (${index + 1}) - ${test.description}`, async () => {
          try {
            await ecLib.invMod(
              web3.utils.toBN(test.input.k),
              web3.utils.toBN(test.input.mod),
            )
          } catch (error) {
            assert(error, test.output.error)
          }
        })
      }

      // deriveY
      for (let [index, test] of curveData.deriveY.valid.entries()) {
        it(`should decode coordinate y from compressed point (${index + 1})`, async () => {
          const coordY = await ecLib.deriveY(
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
      for (let [index, test] of curveData.isOnCurve.valid.entries()) {
        it(`should identify if point is on the curve (${index + 1}) - ${test.output.isOnCurve}`, async () => {
          assert.equal(
            await ecLib.isOnCurve(
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
      for (let [index, test] of curveData.invertPoint.valid.entries()) {
        it(`should invert an EC point (${index + 1})`, async () => {
          const invertedPoint = await ecLib.ecInv(
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
  for (let curve of curves) {
    describe(`Arithmetic operations - Curve ${curve}`, () => {
      const curveData = require(`./data/${curve}.json`)

      // const gx = curveData.params.gx
      // const gy = curveData.params.gy
      const pp = web3.utils.toBN(curveData.params.pp)
      const nn = web3.utils.toBN(curveData.params.nn)
      const aa = web3.utils.toBN(curveData.params.aa)
      // const bb = web3.utils.toBN(curveData.params.bb)
      const lambda = web3.utils.toBN(curveData.params.lambda)
      const beta = web3.utils.toBN(curveData.params.beta)

      let ecLib
      before(async () => {
        ecLib = await EllipticCurve.deployed()
      })

      // Addition
      for (let [index, test] of curveData.addition.valid.entries()) {
        it(`should add two numbers (${index + 1}) - ${test.description}`, async () => {
          const res = await ecLib.ecAdd(
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
      for (let [index, test] of curveData.subtraction.valid.entries()) {
        it(`should subtract two numbers (${index + 1}) - ${test.description}`, async () => {
          const res = await ecLib.ecSub(
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
      for (let [index, test] of curveData.multiplication.valid.entries()) {
        it(`should multiply EC points (${index + 1}) - ${test.description}`, async () => {
          const res = await ecLib.ecMul(
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

      // Scalar decomposition
      for (let [index, test] of curveData.scalarDecomposition.valid.entries()) {
        it(`should decompose an scalar (${index + 1}) - ${test.description}`, async () => {
          const res = await ecLib.scalarDecomposition(
            web3.utils.toBN(test.input.k),
            nn,
            lambda)
          const expectedK1 = web3.utils.toBN(test.output.k1)
          const expectedK2 = web3.utils.toBN(test.output.k2)
          assert.equal(res[0].toString(10), expectedK1.toString())
          assert.equal(res[1].toString(10), expectedK2.toString())
        })
      }

      // Simultaneous multiplication
      for (let [index, test] of curveData.simultaneousMultiplication.valid.entries()) {
        it(`should do a simultaneous multiplication (${index + 1}) - ${test.description}`, async () => {
          const resJac = await ecLib._sim_mul(
            [
              web3.utils.toBN(test.input.k1),
              web3.utils.toBN(test.input.k2),
              web3.utils.toBN(test.input.l1),
              web3.utils.toBN(test.input.l2),
            ],
            [
              web3.utils.toBN(test.input.px),
              web3.utils.toBN(test.input.py),
              web3.utils.toBN(test.input.qx),
              web3.utils.toBN(test.input.qy),
            ],
            aa,
            beta,
            pp
          )
          const resAffine = await ecLib.toAffine(resJac[0], resJac[1], resJac[2], pp)
          const expectedMulX = web3.utils.toBN(test.output.x)
          const expectedMulY = web3.utils.toBN(test.output.y)
          assert.equal(resAffine[0].toString(10), expectedMulX.toString())
          assert.equal(resAffine[1].toString(10), expectedMulY.toString())
        })
      }

      // // MulAddMul
      // for (let [index, test] of curveData.mulAddMul.valid.entries()) {
      //   it(`should do a simultaneous multiplication (${index + 1}) - ${test.description}`, async () => {
      //     const k = await ecLib.scalarDecomposition(
      //       web3.utils.toBN(test.input.k),
      //       nn,
      //       lambda)
      //     const l = await ecLib.scalarDecomposition(
      //       web3.utils.toBN(test.input.l),
      //       nn,
      //       lambda)
      //     const resJac = await ecLib._sim_mul(
      //       [
      //         web3.utils.toBN(k[0]),
      //         web3.utils.toBN(k[1]),
      //         web3.utils.toBN(l[0]),
      //         web3.utils.toBN(l[1]),
      //       ],
      //       [
      //         web3.utils.toBN(test.input.px),
      //         web3.utils.toBN(test.input.py),
      //         web3.utils.toBN(test.input.qx),
      //         web3.utils.toBN(test.input.qy),
      //       ],
      //       aa,
      //       beta,
      //       pp
      //     )
      //     const resAffine = await ecLib.toAffine(resJac[0], resJac[1], resJac[2], pp)
      //     const expectedMulX = web3.utils.toBN(test.output.x)
      //     const expectedMulY = web3.utils.toBN(test.output.y)
      //     assert.equal(resAffine[0].toString(), expectedMulX.toString())
      //     assert.equal(resAffine[1].toString(), expectedMulY.toString())
      //   })
      // }
    })
  }
})
