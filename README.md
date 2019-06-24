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

## Supported curves

The `elliptic-curve-solidity` contract supports up to 256-bit curves. However, it has been extensively tested for the following curves:

- `secp256k1`
- `secp256r1`
- `secp192r1`
- `secp224r1`

Known limitations:

- `deriveY` function does work with curve `secp224r1` because of the selected derivation algorithm. This curve computations are done with a modulo prime `p` such as `p=1  mod 4`, so that more complex algorithm is required (e.g. *Tonelli-Shanks algorithm*). Note that `deriveY` is just an auxiliary function, and thus does not limit the functionality of curve arithmetic operations.

## Usage

`EllipticCurve.sol` contract can be used directly by inheritance or by instantiating it.

The following example depicts how to inherit the library by providing a function to derive a public key from a secret key:

```solidity
pragma solidity ^0.5.0;

import "./EllipticCurve.sol";

contract Secp256k1Example is EllipticCurve {

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

The cost for the aforementioned function is around 550k gas.

```bash
·--------------------------------------------------|--------------------------·
|                      Gas                         · Block limit: 6721975 gas │
···················································|···························
|                 ·          20 gwei/gas           ·      289.62 usd/eth      │
··················|··········|··········|··········|············|··············
|  Method         ·  Min     ·  Max     ·  Avg     ·  # calls   ·  usd (avg)  │
··················|··········|··········|··········|············|··············
|  deriveKey      ·  528127  ·  572545  ·  552976  ·        18  ·       3.20  │
··················|··········|··········|··········|············|··············
```

## Benchmark

Estimation with a gas price of 20 Gwei, derived from [ETH Gas Station](https://ethgasstation.info/):

```bash
·-------------------------------------------------|--------------------------·
|                      Gas                        · Block limit: 6721975 gas │
··················|·······························|···························
|  Methods        ·          20 gwei/gas          ·      267.79 usd/eth      │
··················|·········|··········|··········|············|··············
| Method          ·  Min    ·  Max     ·  Avg     ·  # calls   ·  usd (avg)  │
··················|·········|··········|··········|············|··············
| deriveY         ·  50504  ·   59058  ·   54858  ·         3  ·       0.29  │
··················|·········|··········|··········|············|··············
| ecAdd           ·  29408  ·   61603  ·   48298  ·        12  ·       0.26  │
··················|·········|··········|··········|············|··············
| ecInv           ·  27196  ·   28092  ·   27644  ·         2  ·       0.15  │
··················|·········|··········|··········|············|··············
| ecMul           ·  52150  ·  674698  ·  142639  ·        15  ·       0.76  │
··················|·········|··········|··········|············|··············
| ecSub           ·  55576  ·   61782  ·   58907  ·         4  ·       0.32  │
··················|·········|··········|··········|············|··············
| invMod          ·  23242  ·   52736  ·   37591  ·         4  ·       0.20  │
··················|·········|··········|··········|············|··············
| isOnCurve       ·  28727  ·   30973  ·   29866  ·         4  ·       0.16  │
··················|·········|··········|··········|············|··············
| toAffine        ·  56817  ·   56892  ·   56855  ·         2  ·       0.30  │
··················|·········|··········|··········|············|··············
|  Deployments    ·                                            ·  % of limit ·  
····························|··········|··········|············|··············
|  EllipticCurve  ·    -    ·     -    ·  822657  ·    12.2 %  ·       4.41  │
·-----------------|---------|----------|----------|------------|-------------·
```

*Tested with Solidity 0.5.0 and Truffle v5.0.20.*

## Acknowledgements

Some functions of the contract are based on:

- [Comparatively Study of ECC and Jacobian Elliptic Curve Cryptography](https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf) by Anagha P. Zele and Avinash P. Wadhe
- [Ecsol](https://github.com/jbaylina/ecsol/) written by Jordi Baylina
- [Crypto](https://github.com/androlo/standard-contracts) written by Andreas Olofsson

## License

`elliptic-curve-solidity` is published under the [MIT license][license].

[license]: https://github.com/witnet/elliptic-curve-solidity/blob/master/LICENSE
