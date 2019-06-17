pragma solidity ^0.5.0;

contract EllipticCurve {

  uint256 constant gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 constant gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 constant pp = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint256 constant a = 0;
  uint256 constant b = 7;

  function _jAdd(uint256 x1, uint256 z1, uint256 x2, uint256 z2) public pure returns (uint256 x3, uint256 z3) {
    (x3, z3) = (addmod(mulmod(z2, x1, pp), mulmod(x2, z1, pp), pp), mulmod(z1, z2, pp));
  }

  function _jSub(uint256 x1, uint256 z1, uint256 x2, uint256 z2) public pure returns (uint256 x3, uint256 z3) {
    (x3, z3) = (addmod(mulmod(z2, x1, pp), mulmod(pp - x2, z1, pp), pp), mulmod(z1, z2, pp));
  }

  function _jMul(uint256 x1, uint256 z1, uint256 x2, uint256 z2) public pure returns (uint256 x3, uint256 z3) {
    (x3, z3) = (mulmod(x1, x2, pp), mulmod(z1, z2, pp));
  }

  function _jDiv(uint256 x1, uint256 z1, uint256 x2, uint256 z2) public pure returns (uint256 x3, uint256 z3) {
    (x3, z3) = (mulmod(x1, z2, pp), mulmod(z1, x2, pp));
  }

  function _ecAdd(uint256 x1, uint256 y1, uint256 z1, uint256 x2, uint256 y2, uint256 z2) public pure
  returns (uint256 x3, uint256 y3, uint256 z3) {
    uint256 _l;
    uint256 lz;
    uint256 da;
    uint256 db;

    if ((x1 == 0) && (y1 == 0)) {
      return (x2, y2, z2);
    }

    if ((x2 == 0) && (y2 == 0)) {
      return (x1, y1, z1);
    }

    if ((x1 == x2) && (y1 == y2)) {
      (_l, lz) = _jMul(x1, z1, x1, z1);
      (_l, lz) = _jMul(_l, lz, 3, 1);
      (_l, lz) = _jAdd(_l, lz, a, 1);

      (da, db) = _jMul(y1, z1, 2, 1);
    } else {
      (_l, lz) = _jSub(y2, z2, y1, z1);
      (da, db) = _jSub(x2, z2, x1, z1);
    }

    (_l, lz) = _jDiv(_l, lz, da, db);

    (x3, da) = _jMul(_l, lz, _l, lz);
    (x3, da) = _jSub(x3, da, x1, z1);
    (x3, da) = _jSub(x3, da, x2, z2);

    (y3, db) = _jSub(x1, z1, x3, da);
    (y3, db) = _jMul(y3, db, _l, lz);
    (y3, db) = _jSub(y3, db, y1, z1);

    if (da != db) {
      x3 = mulmod(x3, db, pp);
      y3 = mulmod(y3, da, pp);
      z3 = mulmod(da, db, pp);
    } else {
      z3 = da;
    }
  }

  function _ecDouble(uint256 x1, uint256 y1, uint256 z1) public pure returns (uint256 x3, uint256 y3, uint256 z3) {
    (x3, y3, z3) = _ecAdd(x1, y1, z1, x1, y1, z1);
  }

  function _ecMul(uint256 d, uint256 x1, uint256 y1, uint256 z1) public pure returns (uint256 x3, uint256 y3, uint256 z3) {
    uint256 remaining = d;
    uint256 px = x1;
    uint256 py = y1;
    uint256 pz = z1;
    uint256 acx = 0;
    uint256 acy = 0;
    uint256 acz = 1;

    if (d == 0) {
      return (0, 0, 1);
    }

    while (remaining != 0) {
      if ((remaining & 1) != 0) {
        (acx, acy, acz) = _ecAdd(acx, acy, acz, px, py, pz);
      }
      remaining = remaining / 2;
      (px, py, pz) = _ecDouble(px, py, pz);
    }

    (x3,y3,z3) = (acx, acy, acz);
  }

  /// @dev Modular exponentiation, b^e % m
  /// Basically the same as can be found here:
  /// https://github.com/ethereum/serpent/blob/develop/examples/ecc/modexp.se
  /// @param base The base.
  /// @param e The exponent.
  /// @param m The modulus.
  /// @return x such that x = b**e (mod m)
  function _expMod(uint base, uint e, uint m) internal pure returns (uint r) {
    if (base == 0)
      return 0;
    if (e == 0)
      return 1;
    if (m == 0)
      revert("Modulus by zero");
    r = 1;
    uint bit = 2 ** 255;
    assembly {
      for { } gt(bit, 0) { }{
        r := mulmod(mulmod(r, r, m), exp(base, iszero(iszero(and(e, bit)))), m)
        r := mulmod(mulmod(r, r, m), exp(base, iszero(iszero(and(e, div(bit, 2))))), m)
        r := mulmod(mulmod(r, r, m), exp(base, iszero(iszero(and(e, div(bit, 4))))), m)
        r := mulmod(mulmod(r, r, m), exp(base, iszero(iszero(and(e, div(bit, 8))))), m)
        bit := div(bit, 16)
      }
    }
  }

  function ecInv(uint256 x1, uint256 y1) public pure returns (uint256 x3, uint256 y3) {
    (x3, y3) = (x1, (pp - y1) % pp);
  }

  function ecAdd(uint256 x1, uint256 y1, uint256 x2, uint256 y2) public pure
    returns(uint256 qx, uint256 qy)
  {
    (uint256 x, uint256 y, uint256 z) = _ecAdd(x1, y1, 1, x2, y2, 1);
    z = _invMod(z);
    qx = mulmod(x, z, pp);
    qy = mulmod(y, z, pp);
  }

  function ecSub(uint256 x1, uint256 y1, uint256 x2, uint256 y2) public pure
    returns(uint256 qx, uint256 qy)
  {
    (uint256 x2, uint256 y2) = ecInv(x2, y2);
    (qx, qy) = ecAdd(x1, y1, x2, y2);
  }

  /**
    * @dev Check if a point in affine coordinates is on the curve.
    */
  function isOnCurve(uint x, uint y) public pure returns (bool)
  {
    if (0 == x || x == pp || 0 == y || y == pp) {
      return false;
    }

    uint LHS = mulmod(y, y, pp); // y^2
    uint RHS = mulmod(mulmod(x, x, pp), x, pp); // x^3

    //TODO: To delete if library is no generalized
    if (a != 0) {
      RHS = addmod(RHS, mulmod(x, a, pp), pp); // x^3 + a*x
    }
    //TODO: To delete if library is no generalized
    if (b != 0) {
      RHS = addmod(RHS, b, pp); // x^3 + a*x + b
    }

    return LHS == RHS;
  }

  function _invMod(uint256 x) public pure returns (uint256) {
    if (x == 0 || x == pp || pp == 0) {
      revert("Invalid inputs");
    }

    uint256 t = 0;
    uint256 newT = 1;
    uint256 r = pp;
    uint256 newR = x;
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

}
