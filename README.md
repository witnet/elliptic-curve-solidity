# elliptic-curve-solidity [![](https://travis-ci.com/witnet/elliptic-curve-solidity.svg?branch=master)](https://travis-ci.com/witnet/elliptic-curve-solidity)

`elliptic-curve-solidity` is an open source implementation of Elliptic Curve arithmetic operations written in Solidity.

_DISCLAIMER: This is experimental software. **Use it at your own risk**!_

The solidity library has been generalized in order to support any elliptic curve based on prime numbers up to 256 bits. It provides functions for:

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

`elliptic-curve-solidity` has been designed as a library with **only pure functions** aiming at decreasing gas consumption as much as possible.
A modified library with a constructor for setting the curve parameters can be found at the branch `ref/constructor`.
Additionally, gas consumption comparison can be found in [gas report][benchmark].

## Supported curves

The `elliptic-curve-solidity` contract supports up to 256-bit curves. However, it has been extensively tested for the following curves:

- `secp256k1`
- `secp256r1`
- `secp192r1`
- `secp224r1`

Known limitations:

- `deriveY` function does work with curve `secp224r1` because of the selected derivation algorithm. The computations for this curve are done with a modulo prime `p` such as `p=1  mod 4`, thus a more complex algorithm is required (e.g. *Tonelli-Shanks algorithm*). Note that `deriveY` is just an auxiliary function, and thus does not limit the functionality of curve arithmetic operations.
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

## Benchmark

Gas consumption and USD price estimation with a gas price of 20 Gwei, derived from [ETH Gas Station](https://ethgasstation.info/):

```bash
·---------------------------------------|---------------------------|-------------|----------------------------·
|  Solc version: 0.5.8+commit.23d335f2  ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 6721975 gas  │
········································|···························|·············|·····························
|  Methods                              ·               20 gwei/gas               ·       335.29 usd/eth       │
·····················|··················|·············|·············|·············|··············|··············
|  Contract          ·  Method          ·  Min        ·  Max        ·  Avg        ·  # calls     ·  usd (avg)  │
·····················|··················|·············|·············|·············|··············|··············
|  EllipticCurve     ·  deriveY         ·      50504  ·      59058  ·      54858  ·           6  ·       0.37  │
·····················|··················|·············|·············|·············|··············|··············
|  EllipticCurve     ·  ecAdd           ·      29408  ·      61603  ·      48298  ·          24  ·       0.32  │
·····················|··················|·············|·············|·············|··············|··············
|  EllipticCurve     ·  ecInv           ·      27196  ·      28092  ·      27644  ·           4  ·       0.19  │
·····················|··················|·············|·············|·············|··············|··············
|  EllipticCurve     ·  ecMul           ·      52150  ·     674698  ·     137948  ·          29  ·       0.93  │
·····················|··················|·············|·············|·············|··············|··············
|  EllipticCurve     ·  ecSub           ·      55576  ·      61782  ·      58907  ·           8  ·       0.40  │
·····················|··················|·············|·············|·············|··············|··············
|  EllipticCurve     ·  invMod          ·      23242  ·      52736  ·      37591  ·           8  ·       0.25  │
·····················|··················|·············|·············|·············|··············|··············
|  EllipticCurve     ·  isOnCurve       ·      28727  ·      30973  ·      29866  ·           8  ·       0.20  │
·····················|··················|·············|·············|·············|··············|··············
|  EllipticCurve     ·  toAffine        ·      56817  ·      56892  ·      56855  ·           4  ·       0.38  │
·····················|··················|·············|·············|·············|··············|··············
|  Deployments                          ·                                         ·  % of limit  ·             │
········································|·············|·············|·············|··············|··············
|  EllipticCurve                        ·          -  ·          -  ·     822657  ·      12.2 %  ·       5.52  │
·---------------------------------------|-------------|-------------|-------------|--------------|-------------·
```

More detailed results can be found in [gas report][benchmark].

## Acknowledgements

Some functions of the contract are based on:

- [Comparatively Study of ECC and Jacobian Elliptic Curve Cryptography](https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf) by Anagha P. Zele and Avinash P. Wadhe
- [Ecsol](https://github.com/jbaylina/ecsol/) written by Jordi Baylina
- [Crypto](https://github.com/androlo/standard-contracts) written by Andreas Olofsson

## License

`elliptic-curve-solidity` is published under the [MIT license][license].

[license]: https://github.com/witnet/elliptic-curve-solidity/blob/master/LICENSE
[benchmark]: https://github.com/witnet/elliptic-curve-solidity/blob/master/benchmark/GAS.md
