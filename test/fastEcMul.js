const EllipticCurve = artifacts.require("./TestEllipticCurve")

contract("FastEcMul", accounts => {
  const curves = ["secp256k1", "secp192k1", "secp224k1", "P256", "P192", "P224"]

  for (const curve of curves) {
    describe(`Arithmetic operations - Curve ${curve}`, () => {
      const curveData = require(`./data/${curve}.json`)

      const pp = web3.utils.toBN(curveData.params.pp)
      const nn = web3.utils.toBN(curveData.params.nn)
      const aa = web3.utils.toBN(curveData.params.aa)
      const lambda = web3.utils.toBN(curveData.params.lambda)
      const beta = web3.utils.toBN(curveData.params.beta)

      let fastEcMul
      before(async () => {
        fastEcMul = await EllipticCurve.new()
      })

      // Scalar decomposition
      for (const [index, test] of curveData.decomposeScalar.valid.entries()) {
        it(`should decompose an scalar (${index + 1}) - ${test.description}`, async () => {
          const res = await fastEcMul.decomposeScalar.call(
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
      for (const [index, test] of curveData.simMul.valid.entries()) {
        it(`should do a simultaneous multiplication (${index + 1}) - ${test.description}`, async () => {
          const res = await fastEcMul.ecSimMul.call(
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
          const expectedMulX = web3.utils.toBN(test.output.x)
          const expectedMulY = web3.utils.toBN(test.output.y)
          assert.equal(res[0].toString(10), expectedMulX.toString())
          assert.equal(res[1].toString(10), expectedMulY.toString())
        })
      }

      // MulAddMul
      for (const [index, test] of curveData.mulAddMul.valid.entries()) {
        it(`should do decompose scalar and simult. multiplication (${index + 1}) - ${test.description}`, async () => {
          const k = await fastEcMul.decomposeScalar.call(
            web3.utils.toBN(test.input.k),
            nn,
            lambda)
          const l = await fastEcMul.decomposeScalar.call(
            web3.utils.toBN(test.input.l),
            nn,
            lambda)
          const res = await fastEcMul.ecSimMul.call(
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
          const expectedMulX = web3.utils.toBN(test.output.x)
          const expectedMulY = web3.utils.toBN(test.output.y)
          assert.equal(res[0].toString(), expectedMulX.toString())
          assert.equal(res[1].toString(), expectedMulY.toString())
        })
      }
    })
  }
})
