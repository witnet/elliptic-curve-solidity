pragma solidity ^0.5.0;

/**
 * @title EcUtils
 *
 * Functions for operating with EC points...
 *
 */
library EcUtils {

  /// @dev Modular euclidean inverse of a (mod p)
  /// Conditions: 'a' and 'pp' must be co-pp
  /// @param a The number
  /// @param pp The modulus
  /// @return x such that ax = 1 (mod p)
  function invMod(uint256 a, uint256 pp) public pure returns (uint256) {
    if (a == 0 || a == pp || pp == 0) {
      revert("Invalid inputs");
    }

    uint256 t = 0;
    uint256 newT = 1;
    uint256 r = pp;
    uint256 newR = a;
    uint256 q;

    if (newR > pp) {
      newR = newR % pp;
    }

    while (newR != 0) {
      q = r / newR;
      (t, newT) = (newT, addmod(t, (pp - mulmod(q, newT, pp)), pp));
      (r, newR) = (newR, r - q * newR);
    }

    return uint(t);
  }

  /// @dev Modular exponentiation, b^e % pp
  /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
  /// @param base base
  /// @param e exponent
  /// @param pp modulus
  /// @return x such that x = b**e (mod pp)
  function expMod(uint256 base, uint256 e, uint256 pp) internal pure returns (uint256) {
    if (base == 0)
      return 0;
    if (e == 0)
      return 1;
    if (pp == 0)
      revert("Modulus is zero");
    uint256 r = 1;
    uint256 bit = 2 ** 255;

    assembly {
      for { } gt(bit, 0) { }{
        r := mulmod(mulmod(r, r, pp), exp(base, iszero(iszero(and(e, bit)))), pp)
        r := mulmod(mulmod(r, r, pp), exp(base, iszero(iszero(and(e, div(bit, 2))))), pp)
        r := mulmod(mulmod(r, r, pp), exp(base, iszero(iszero(and(e, div(bit, 4))))), pp)
        r := mulmod(mulmod(r, r, pp), exp(base, iszero(iszero(and(e, div(bit, 8))))), pp)
        bit := div(bit, 16)
      }
    }

    return r;
  }

  /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1)
  /// @param x coordinate x
  /// @param y coordinate y
  /// @param z coordinate z
  /// @param pp the modulus
  /// @return (x', y') affine coordinates
  function toZ1(uint x, uint y, uint z, uint pp) public pure returns (uint, uint) {
    uint zInv = invMod(y, pp);
    uint zInv2 = mulmod(zInv, zInv, pp);
    uint qx = mulmod(x, zInv2, pp);
    uint qy = mulmod(y, mulmod(zInv, zInv2, pp), pp);

    return (qx, qy);
  }

}