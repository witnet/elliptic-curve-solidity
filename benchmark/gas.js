const EcGasHelper = artifacts.require("EcGasHelper")
const EllipticCurve = artifacts.require("../contracts/EllipticCurve")

contract("EcGasHelper - Gas consumption analysis", accounts => {
  // /////////////////////////////////////////// //
  // Check auxiliary operations for given curves //
  // /////////////////////////////////////////// //
  const auxCurves = ["secp256k1", "P256"]
  for (let curve of auxCurves) {
    describe(`Aux. operations - Curve ${curve}`, () => {
      const curveData = require(`../test/data/${curve}-aux.json`)

      const pp = web3.utils.toBN(curveData.params.pp)
      const aa = web3.utils.toBN(curveData.params.aa)
      const bb = web3.utils.toBN(curveData.params.bb)

      let helper
      before(async () => {
        await EllipticCurve.deployed()
        await EcGasHelper.link(EllipticCurve)
        helper = await EcGasHelper.new()
      })

      // toAffine
      for (let [index, test] of curveData.toAffine.valid.entries()) {
        it(`should convert a Jacobian point to affine (${index + 1})`, async () => {
          await helper._toAffine(
            web3.utils.toBN(test.input.x),
            web3.utils.toBN(test.input.y),
            web3.utils.toBN(test.input.z),
            pp
          )
        })
      }

      // invMod
      for (let [index, test] of curveData.invMod.valid.entries()) {
        it(`should invert a scalar (${index + 1}) - ${test.description}`, async () => {
          await helper._invMod(
            web3.utils.toBN(test.input.k),
            pp,
          )
        })
      }

      // deriveY
      for (let [index, test] of curveData.deriveY.valid.entries()) {
        it(`should decode coordinate y from compressed point (${index + 1})`, async () => {
          await helper._deriveY(
            web3.utils.hexToBytes(test.input.sign),
            web3.utils.hexToBytes(test.input.x),
            aa,
            bb,
            pp
          )
        })
      }

      // isOnCurve
      for (let [index, test] of curveData.isOnCurve.valid.entries()) {
        it(`should identify if point is on the curve (${index + 1}) - ${test.output.isOnCurve}`, async () => {
          await helper._isOnCurve(
            web3.utils.hexToBytes(test.input.x),
            web3.utils.hexToBytes(test.input.y),
            aa,
            bb,
            pp)
        })
      }

      // invertPoint
      for (let [index, test] of curveData.invertPoint.valid.entries()) {
        it(`should invert an EC point (${index + 1})`, async () => {
          await helper._ecInv(
            web3.utils.hexToBytes(test.input.x),
            web3.utils.hexToBytes(test.input.y),
            pp
          )
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
      const curveData = require(`../test/data/${curve}.json`)

      const pp = web3.utils.toBN(curveData.params.pp)
      const nn = web3.utils.toBN(curveData.params.nn)
      const aa = web3.utils.toBN(curveData.params.aa)
      const lambda = web3.utils.toBN(curveData.params.lambda)
      const beta = web3.utils.toBN(curveData.params.beta)

      let ecLib, helper
      before(async () => {
        ecLib = await EllipticCurve.deployed()
        await EcGasHelper.link(EllipticCurve)
        helper = await EcGasHelper.new()
      })

      // Addition
      for (let [index, test] of curveData.addition.valid.entries()) {
        it(`should add two numbers (${index + 1}) - ${test.description}`, async () => {
          await helper._ecAdd(
            web3.utils.toBN(test.input.x1),
            web3.utils.toBN(test.input.y1),
            web3.utils.toBN(test.input.x2),
            web3.utils.toBN(test.input.y2),
            aa,
            pp
          )
        })
      }

      // Subtraction
      for (let [index, test] of curveData.subtraction.valid.entries()) {
        it(`should subtract two numbers (${index + 1}) - ${test.description}`, async () => {
          await helper._ecSub(
            web3.utils.toBN(test.input.x1),
            web3.utils.toBN(test.input.y1),
            web3.utils.toBN(test.input.x2),
            web3.utils.toBN(test.input.y2),
            aa,
            pp
          )
        })
      }

      // Multiplication
      for (let [index, test] of curveData.multiplication.valid.entries()) {
        it(`should multiply EC points (${index + 1}) - ${test.description}`, async () => {
          await helper._ecMul(
            web3.utils.toBN(test.input.k),
            web3.utils.toBN(test.input.x),
            web3.utils.toBN(test.input.y),
            aa,
            pp
          )
        })
      }

      // Scalar decomposition
      for (let [index, test] of curveData.decomposeScalar.valid.entries()) {
        it(`should decompose an scalar (${index + 1}) - ${test.description}`, async () => {
          await helper._decomposeScalar(
            web3.utils.toBN(test.input.k),
            nn,
            lambda)
        })
      }

      // Simultaneous multiplication
      for (let [index, test] of curveData.simMul.valid.entries()) {
        it(`should do a simultaneous multiplication (${index + 1}) - ${test.description}`, async () => {
          await helper._ecSimMul(
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
        })
      }

      // MulAddMul
      for (let [index, test] of curveData.mulAddMul.valid.entries()) {
        it(`should do decompose scalar and simult. multiplication (${index + 1}) - ${test.description}`, async () => {
          const k = await ecLib.decomposeScalar(
            web3.utils.toBN(test.input.k),
            nn,
            lambda)
          await helper._decomposeScalar(
            web3.utils.toBN(test.input.k),
            nn,
            lambda)
          const l = await ecLib.decomposeScalar(
            web3.utils.toBN(test.input.l),
            nn,
            lambda)
          await helper._decomposeScalar(
            web3.utils.toBN(test.input.l),
            nn,
            lambda)
          await helper._ecSimMul(
            [
              web3.utils.toBN(k[0]),
              web3.utils.toBN(k[1]),
              web3.utils.toBN(l[0]),
              web3.utils.toBN(l[1]),
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
        })
      }
    })
  }
})
