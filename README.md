# elliptic-curve-solidity [![npm version](https://badge.fury.io/js/elliptic-curve-solidity.svg)](https://badge.fury.io/js/elliptic-curve-solidity) [![TravisCI](https://travis-ci.com/witnet/elliptic-curve-solidity.svg?branch=master)](https://travis-ci.com/witnet/elliptic-curve-solidity)

`elliptic-curve-solidity` is an open source implementation of Elliptic Curve arithmetic operations written in Solidity.

_DISCLAIMER: This is experimental software. **Use it at your own risk**!_

The solidity library has been generalized in order to support any elliptic curve based on prime numbers up to 256 bits. It provides functions for:

- Modular
  - inverse
  - exponentiation
  - scalar decomposition
- Jacobian coordinates
  - addition
  - double
  - multiplication
- Affine coordinates
  - inverse
  - addition
  - subtraction
  - multiplication
  - simultaneous multiplication (using wNAF)
- Auxiliary
  - conversion to affine coordinates
  - derive coordinate Y from compressed ec point
  - check if ec point is on curve

`elliptic-curve-solidity` has been designed as a library with **only pure functions** aiming at decreasing gas consumption as much as possible.
A modified library with a constructor for setting the curve parameters can be found at the branch `ref/constructor`.
Additionally, gas consumption comparison can be found in [gas report][benchmark].

## Supported curves

The `elliptic-curve-solidity` contract supports up to 256-bit curves. However, it has been extensively tested for the following curves:

- `secp256k1`
- `secp224k1`
- `secp192k1`
- `secp256r1`
- `secp192r1`
- `secp224r1`

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
|                 ·          20 gwei/gas           ·      289.62 usd/eth      │
··················|··········|··········|··········|············|··············
|  Method         ·  Min     ·  Max     ·  Avg     ·  # calls   ·  usd (avg)  │
··················|··········|··········|··········|············|··············
|  deriveKey      ·  528127  ·  572545  ·  552976  ·        18  ·       3.71  │
··················|··········|··········|··········|············|··············
```

The cost of a simultaneous multiplication (using wNAF) consumes around 35% of the gas required by 2 EC multiplications.

## Benchmark

Gas consumption and USD price estimation with a gas price of 20 Gwei, derived from [ETH Gas Station](https://ethgasstation.info/):

```bash
·---------------------------------------|---------------------------|-------------|----------------------------·
|  Solc version: 0.5.8+commit.23d335f2  ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 6721975 gas  │
········································|···························|·············|·····························
|  Methods                              ·               20 gwei/gas               ·       169.15 usd/eth       │
···················|····················|·············|·············|·············|··············|··············
|  Contract        ·  Method            ·  Min        ·  Max        ·  Avg        ·  # calls     ·  usd (avg)  │
···················|····················|·············|·············|·············|··············|··············
|  EllipticCurve   ·  decomposeScalar   ·     656255  ·    1083667  ·    1054756  ·          17  ·       3.57  │
···················|····················|·············|·············|·············|··············|··············
|  EllipticCurve   ·  deriveY           ·      50485  ·      59039  ·      54762  ·           8  ·       0.19  │
···················|····················|·············|·············|·············|··············|··············
|  EllipticCurve   ·  ecAdd             ·      48747  ·      64887  ·      57093  ·         468  ·       0.19  │
···················|····················|·············|·············|·············|··············|··············
|  EllipticCurve   ·  ecInv             ·      27285  ·      28181  ·      27733  ·           4  ·       0.09  │
···················|····················|·············|·············|·············|··············|··············
|  EllipticCurve   ·  ecMul             ·      29163  ·     683483  ·     385920  ·         561  ·       1.31  │
···················|····················|·············|·············|·············|··············|··············
|  EllipticCurve   ·  ecSimMul          ·      91299  ·     521542  ·     276388  ·           7  ·       0.94  │
···················|····················|·············|·············|·············|··············|··············
|  EllipticCurve   ·  ecSub             ·      48926  ·      64712  ·      57395  ·         228  ·       0.19  │
···················|····················|·············|·············|·············|··············|··············
|  EllipticCurve   ·  invMod            ·      23245  ·      52739  ·      42166  ·          12  ·       0.14  │
···················|····················|·············|·············|·············|··············|··············
|  EllipticCurve   ·  toAffine          ·      56836  ·      56911  ·      56874  ·           4  ·       0.19  │
···················|····················|·············|·············|·············|··············|··············
|  Migrations      ·  setCompleted      ·          -  ·          -  ·      26939  ·           1  ·       0.09  │
···················|····················|·············|·············|·············|··············|··············
|  Deployments                          ·                                         ·  % of limit  ·             │
········································|·············|·············|·············|··············|··············
|  EllipticCurve                        ·          -  ·          -  ·    1869605  ·      27.8 %  ·       6.32  │
·---------------------------------------|-------------|-------------|-------------|--------------|-------------·
```

More detailed results can be found in [gas report][benchmark].

## Acknowledgements

Some functions of the contract are based on:

- [Comparatively Study of ECC and Jacobian Elliptic Curve Cryptography](https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf) by Anagha P. Zele and Avinash P. Wadhe
- [Ecsol](https://github.com/jbaylina/ecsol/) written by Jordi Baylina
- [Crypto](https://github.com/androlo/standard-contracts) written by Andreas Olofsson
- [Numerology](https://github.com/nucypher/numerology/blob/master/contracts/Numerology.sol) by nucypher

## License

`elliptic-curve-solidity` is published under the [MIT license][license].

[license]: https://github.com/witnet/elliptic-curve-solidity/blob/master/LICENSE
[benchmark]: https://github.com/witnet/elliptic-curve-solidity/blob/master/benchmark/GAS.md
