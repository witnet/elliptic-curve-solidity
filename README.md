# elliptic-curve-solidity [![npm version](https://badge.fury.io/js/elliptic-curve-solidity.svg)](https://badge.fury.io/js/elliptic-curve-solidity) [![TravisCI](https://travis-ci.com/witnet/elliptic-curve-solidity.svg?branch=master)](https://travis-ci.com/witnet/elliptic-curve-solidity)

`elliptic-curve-solidity` is an open source implementation of Elliptic Curve arithmetic operations written in Solidity.

_DISCLAIMER: This is experimental software. **Use it at your own risk**!_

The solidity contracts have been generalized in order to support any elliptic curve based on prime numbers up to 256 bits.

`elliptic-curve-solidity` has been designed as a library with **only pure functions** aiming at decreasing gas consumption as much as possible. Additionally, gas consumption comparison can be found in the benchmark section.
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
  - derive coordinate Y from compressed ec point
  - check if ec point is on curve

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

`EllipticCurve.sol` contract can be used directly by inheritance or by instantiating it.

The [Secp256k1](https://github.com/witnet/elliptic-curve-solidity/blob/master/examples/Secp256k1.sol) example depicts how to inherit the library by providing a function to derive a public key from a secret key:

```solidity
pragma solidity ^0.5.0;

import "./EllipticCurve.sol";

contract Secp256k1 is EllipticCurve {

  uint256 constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint256 constant AA = 0;
  uint256 constant BB = 7;

  function derivePubKey(uint256 privKey) public pure returns(uint256 qx, uint256 qy) {
    (qx, qy) = ecMul(
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
|                 ·          20 gwei/gas           ·      170.72 usd/eth      │
··················|··········|··········|··········|············|··············
|  Method         ·  Min     ·  Max     ·  Avg     ·  # calls   ·  usd (avg)  │
··················|··········|··········|··········|············|··············
|  derivePubKey   ·  538288  ·  583518  ·  563556  ·        18  ·       1.92  │
··················|··········|··········|··········|············|··············
```

The cost of a simultaneous multiplication (using wNAF) consumes around 35% of the gas required by 2 EC multiplications.

## Benchmark

Gas consumption and USD price estimation with a gas price of 20 Gwei, derived from [ETH Gas Station](https://ethgasstation.info/):

```bash
·---------------------------------------|---------------------------|-------------|----------------------------·
|  Solc version: 0.5.8+commit.23d335f2  ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 6721975 gas  │
········································|···························|·············|·····························
|  Methods                              ·               20 gwei/gas               ·       169.63 usd/eth       │
··················|·····················|·············|·············|·············|··············|··············
|  Contract       ·  Method             ·  Min        ·  Max        ·  Avg        ·  # calls     ·  usd (avg)  │
··················|·····················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _decomposeScalar   ·     658191  ·    1085603  ·     943298  ·         134  ·       3.20  │
··················|·····················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _deriveY           ·      52544  ·      61098  ·      56821  ·           4  ·       0.19  │
··················|·····················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecAdd             ·      50892  ·      67032  ·      59238  ·         468  ·       0.20  │
··················|·····················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecInv             ·      29220  ·      30116  ·      29668  ·           2  ·       0.10  │
··················|·····················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecMul             ·      31305  ·     695810  ·     393472  ·         561  ·       1.33  │
··················|·····················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecSimMul          ·      94010  ·     531737  ·     272883  ·         125  ·       0.93  │
··················|·····················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _ecSub             ·      51138  ·      66924  ·      59607  ·         228  ·       0.20  │
··················|·····················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _invMod            ·      25111  ·      54605  ·      44032  ·          12  ·       0.15  │
··················|·····················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _isOnCurve         ·      30763  ·      33009  ·      31902  ·           8  ·       0.11  │
··················|·····················|·············|·············|·············|··············|··············
|  EcGasHelper    ·  _toAffine          ·      58922  ·      58997  ·      58960  ·           4  ·       0.20  │
··················|·····················|·············|·············|·············|··············|··············
|  Deployments                          ·                                         ·  % of limit  ·             │
········································|·············|·············|·············|··············|··············
|  EcGasHelper                          ·          -  ·          -  ·     690055  ·      10.3 %  ·       2.34  │
········································|·············|·············|·············|··············|··············
|  EllipticCurve                        ·          -  ·          -  ·    1876205  ·      27.9 %  ·       6.40  │
·---------------------------------------|-------------|-------------|-------------|--------------|-------------·
```

More detailed results can be found in [gas report][benchmark].

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
