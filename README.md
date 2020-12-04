# elliptic-curve-solidity [![npm version](https://badge.fury.io/js/elliptic-curve-solidity.svg)](https://badge.fury.io/js/elliptic-curve-solidity) [![TravisCI](https://travis-ci.com/witnet/elliptic-curve-solidity.svg?branch=master)](https://travis-ci.com/witnet/elliptic-curve-solidity) [![Coverage Status](https://coveralls.io/repos/github/witnet/elliptic-curve-solidity/badge.svg?branch=master)](https://coveralls.io/github/witnet/elliptic-curve-solidity?branch=master)

`elliptic-curve-solidity` is an open source implementation of Elliptic Curve arithmetic operations written in Solidity.

_DISCLAIMER: This is experimental software. **Use it at your own risk**!_

The solidity contracts have been generalized in order to support any elliptic curve based on prime numbers up to 256 bits.

`elliptic-curve-solidity` has been designed as a library with **only pure functions** aiming at decreasing gas consumption as much as possible. Additionally, gas consumption comparison can be found in the benchmark section. This library **does not check whether the points passed as arguments to the library belong to the curve**. However, the library exposes a method called *`isOnCurve`* that can be utilized before using the library functions.

It contains 2 solidity libraries:

1. `EllipticCurve.sol`: provides main elliptic curve operations in affine and Jacobian coordinates.
2. `FastEcMul.sol`: provides a fast elliptic curve multiplication by using scalar decomposition and wNAF scalar representation.

`EllipticCurve` library provides functions for:

- Modular
  - inverse
  - exponentiation
- Jacobian coordinates
  - addition
  - double
  - multiplication
- Affine coordinates
  - inverse
  - addition
  - subtraction
  - multiplication
- Auxiliary
  - conversion to affine coordinates
  - derive coordinate Y from compressed EC point
  - check if EC point is on curve

`FastEcMul` library provides support for:

- Scalar decomposition
- Simultaneous multiplication (computes 2 EC multiplications using wNAF scalar representation)

## Supported curves

The `elliptic-curve-solidity` contract supports up to 256-bit curves. However, it has been extensively tested for the following curves:

- `secp256k1`
- `secp224k1`
- `secp192k1`
- `secp256r1` (aka P256)
- `secp192r1` (aka P192)
- `secp224r1` (aka P224)

Known limitations:

- `deriveY` function do not work with the curves `secp224r1` and `secp224k1` because of the selected derivation algorithm. The computations for this curve are done with a modulo prime `p` such that `p mod 4 = 1`, thus a more complex algorithm is required (e.g. *Tonelli-Shanks algorithm*). Note that `deriveY` is just an auxiliary function, and thus does not limit the functionality of curve arithmetic operations.
- the library only supports elliptic curves with `cofactor = 1` (all supported curves have a `cofactor = 1`).

## Usage

`EllipticCurve.sol` library can be used directly by importing it.

The [Secp256k1](https://github.com/witnet/elliptic-curve-solidity/blob/master/examples/Secp256k1.sol) example depicts how to use the library by providing a function to derive a public key from a secret key:

```solidity
pragma solidity 0.6.12;

import "elliptic-curve-solidity/contracts/EllipticCurve.sol";


contract Secp256k1 {

  uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 public constant AA = 0;
  uint256 public constant BB = 7;
  uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

  function derivePubKey(uint256 privKey) public pure returns(uint256 qx, uint256 qy) {
    (qx, qy) = EllipticCurve.ecMul(
      privKey,
      GX,
      GY,
      AA,
      PP
    );
  }
}
```

The cost of a key derivation operation in Secp256k1 is around 550k gas.

```bash
·--------------------------------------------------|--------------------------·
|                      Gas                         · Block limit: 6721975 gas │
···················································|···························
|                 ·          100 gwei/gas           ·     592.30 usd/eth      │
··················|··········|··········|··········|············|··············
|  Method         ·  Min     ·  Max     ·  Avg     ·  # calls   ·  usd (avg)  │
··················|··········|··········|··········|············|··············
|  derivePubKey   ·  476146  ·  518863  ·  499884  ·        18  ·      29.61  │
··················|··········|··········|··········|············|··············
```

The cost of a simultaneous multiplication (using wNAF) consumes around 35% of the gas required by 2 EC multiplications.

## Benchmark

Gas consumption and USD price estimation with a gas price of 100 Gwei, derived from [ETH Gas Station](https://ethgasstation.info/):

```bash
·----------------------------------------|---------------------------|-------------|----------------------------·
|  Solc version: 0.6.12+commit.27d51765  ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 6718946 gas  │
·········································|···························|·············|·····························
|  Methods                               ·              100 gwei/gas               ·       613.52 usd/eth       │
··················|······················|·············|·············|·············|··············|··············
|  Contract       ·  Method              ·  Min        ·  Max        ·  Avg        ·  # calls     ·  usd (avg)  │
··················|······················|·············|·············|·············|··············|··············
|  EllipticCurve  ·  decomposeScalar     ·      55811  ·      65399  ·      61939  ·         134  ·       3.80  │
··················|······················|·············|·············|·············|··············|··············
|  EllipticCurve  ·  deriveY             ·      45275  ·      55545  ·      50410  ·           4  ·       3.09  │
··················|······················|·············|·············|·············|··············|··············
|  EllipticCurve  ·  ecAdd               ·      24305  ·      56323  ·      49119  ·         472  ·       3.01  │
··················|······················|·············|·············|·············|··············|··············
|  EllipticCurve  ·  ecInv               ·      22906  ·      23074  ·      22990  ·           2  ·       1.41  │
··················|······················|·············|·············|·············|··············|··············
|  EllipticCurve  ·  ecMul               ·      24911  ·     623087  ·     350939  ·         561  ·      21.53  │
··················|······················|·············|·············|·············|··············|··············
|  EllipticCurve  ·  ecSimMul            ·      76465  ·     488165  ·     243763  ·         125  ·      14.96  │
··················|······················|·············|·············|·············|··············|··············
|  EllipticCurve  ·  ecSub               ·      42634  ·      56236  ·      49717  ·         228  ·       3.05  │
··················|······················|·············|·············|·············|··············|··············
|  EllipticCurve  ·  invMod              ·      22153  ·      49255  ·      39627  ·          12  ·       2.43  │
··················|······················|·············|·············|·············|··············|··············
|  EllipticCurve  ·  isOnCurve           ·      23400  ·      24071  ·      23623  ·          16  ·       1.45  │
··················|······················|·············|·············|·············|··············|··············
|  EllipticCurve  ·  toAffine            ·      50145  ·      50850  ·      50498  ·           4  ·       3.10  │
·----------------------------------------|-------------|-------------|-------------|--------------|-------------·
```

## Acknowledgements

Some functions of the contract are based on:

- [Comparatively Study of ECC and Jacobian Elliptic Curve Cryptography](https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf) by Anagha P. Zele and Avinash P. Wadhe
- [`Numerology`](https://github.com/nucypher/numerology) by NuCypher
- [`solidity-arithmetic`](https://github.com/gnosis/solidity-arithmetic) by Gnosis
- [`ecsol`](https://github.com/jbaylina/ecsol) written by Jordi Baylina
- [`standard contracts`](https://github.com/androlo/standard-contracts) written by Andreas Olofsson

## License

`elliptic-curve-solidity` is published under the [MIT license][license].

[license]: https://github.com/witnet/elliptic-curve-solidity/blob/master/LICENSE
