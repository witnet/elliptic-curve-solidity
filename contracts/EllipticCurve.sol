pragma solidity ^0.5.0;

/**
 * @title Elliptic Curve Library
 * @dev Library providing arithmetic operations over elliptic curves
 * @author Witnet Foundation
 */


contract EllipticCurve {

  /// @dev Modular euclidean inverse of a number (mod p)
  /// @param x The number
  /// @param pp The modulus
  /// @return q such that x*q = 1 (mod pp)
  function invMod(uint256 x, uint256 pp) public pure returns (uint256 q) {
    if (x == 0 || x == pp || pp == 0) {
      revert("Invalid number");
    }
    q = 0;
    uint256 newT = 1;
    uint256 r = pp;
    uint256 newR = x;
    uint256 t;
    while (newR != 0) {
      t = r / newR;
      (q, newT) = (newT, addmod(q, (pp - mulmod(t, newT, pp)), pp));
      (r, newR) = (newR, r - t * newR );
    }
  }

  /// @dev Modular exponentiation, b^e % pp
  /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
  /// @param base base
  /// @param e exponent
  /// @param pp modulus
  /// @return r such that r = b**e (mod pp)
  function expMod(uint256 base, uint256 e, uint256 pp) public pure returns (uint256 r) {
    if (base == 0)
      return 0;
    if (e == 0)
      return 1;
    if (pp == 0)
      revert("Modulus is zero");
    r = 1;
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
  }

  /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1)
  /// @param x coordinate x
  /// @param y coordinate y
  /// @param z coordinate z
  /// @param pp the modulus
  /// @return (x', y') affine coordinates
  function toAffine(
    uint256 x,
    uint256 y,
    uint256 z,
    uint pp)
  public pure returns (uint256 x2, uint256 y2)
  {
    uint zInv = invMod(z, pp);
    uint zInv2 = mulmod(zInv, zInv, pp);
    x2 = mulmod(x, zInv2, pp);
    y2 = mulmod(y, mulmod(zInv, zInv2, pp), pp);
  }

  /// @dev Derives the y coordinate from a compressed-format point x
  /// @param prefix parity byte (0x02 even, 0x03 odd)
  /// @param x coordinate x
  /// @param a constant of curve
  /// @param b constant of curve
  /// @param pp the modulus
  /// @return y coordinate y
  function deriveY(
    uint8 prefix,
    uint256 x,
    uint256 a,
    uint256 b,
    uint256 pp)
  public pure returns (uint256 y)
  {
    // x^3 + ax + b
    uint256 y2 = addmod(mulmod(x, mulmod(x, x, pp), pp), addmod(mulmod(x, a, pp), b, pp), pp);
    uint256 y_ = expMod(y2, (pp + 1) / 4, pp);
    // uint256 cmp = yBit ^ y_ & 1;
    y = (y_ + prefix) % 2 == 0 ? y_ : pp - y_;
  }

  /// @dev Check whether point (x,y) is on curve defined by a, b, and pp.
  /// @param x coordinate x of P1
  /// @param y coordinate y of P1
  /// @param a constant of curve
  /// @param b constant of curve
  /// @param pp the modulus
  /// @return true if x,y in the curve, false else
  function isOnCurve(
    uint x,
    uint y,
    uint a,
    uint b,
    uint pp)
  public pure returns (bool)
  {
    if (0 == x || x == pp || 0 == y || y == pp) {
      return false;
    }
    // y^2
    uint lhs = mulmod(y, y, pp);
    // x^3
    uint rhs = mulmod(mulmod(x, x, pp), x, pp);
    if (a != 0) {
      // x^3 + a*x
      rhs = addmod(rhs, mulmod(x, a, pp), pp);
    }
    if (b != 0) {
      // x^3 + a*x + b
      rhs = addmod(rhs, b, pp);
    }

    return lhs == rhs;
  }

  /// @dev Calculate inverse (x, -y) of point (x, y).
  /// @param x coordinate x of P1
  /// @param y coordinate y of P1
  /// @param pp the modulus
  /// @return (x, -y)
  function ecInv(
    uint256 x,
    uint256 y,
    uint256 pp)
  public pure returns (uint256 qx, uint256 qy)
  {
    (qx, qy) = (x, (pp - y) % pp);
  }

  /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param x1 coordinate x of P1
  /// @param y1 coordinate y of P1
  /// @param x2 coordinate x of P2
  /// @param y2 coordinate y of P2
  /// @param a constant of the curve
  /// @param pp the modulus
  /// @return (qx, qy) = P1+P2 in affine coordinates
  function ecAdd(
    uint256 x1,
    uint256 y1,
    uint256 x2,
    uint256 y2,
    uint256 a,
    uint256 pp)
    public pure returns(uint256 qx, uint256 qy)
  {
    uint x = 0;
    uint y = 0;
    uint z = 0;
    // Double if x1==x2 else add
    if (x1==x2) {
      (x, y, z) = jacDouble(
        x1,
        y1,
        1,
        a,
        pp);
    } else {
      (x, y, z) = jacAdd(
        x1,
        y1,
        1,
        x2,
        y2,
        1,
        pp);
    }
    // Get back to affine
    (qx, qy) = toAffine(
      x,
      y,
      z,
      pp);
  }

  /// @dev Substract two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param x1 coordinate x of P1
  /// @param y1 coordinate y of P1
  /// @param x2 coordinate x of P2
  /// @param y2 coordinate y of P2
  /// @param a constant of the curve
  /// @param pp the modulus
  /// @return (qx, qy) = P1-P2 in affine coordinates
  function ecSub(
    uint256 x1,
    uint256 y1,
    uint256 x2,
    uint256 y2,
    uint256 a,
    uint256 pp)
  public pure returns(uint256 qx, uint256 qy)
  {
    // invert square
    (uint256 x, uint256 y) = ecInv(x2, y2, pp);
    // P1-square
    (qx, qy) = ecAdd(
      x1,
      y1,
      x,
      y,
      a,
      pp);
  }

  /// @dev Decomposition of the scalar k in two scalars k1 and k2 with half bit-length, such that k=k1+k2*LAMBDA (mod n)
  /// @param _k the scalar to be decompose
  /// @param _pp the modulus
  /// @param _LAMBDA is a root of the characteristic polynomial of an endomorphism of the curve
  /// @return k1 and k2  such that k=k1+k2*LAMBDA (mod n)
  function scalarDecomposition (uint256 _k, uint256 _pp, uint256 _LAMBDA) public pure returns (int256[2] memory) {
  // Extended Euclidean Algorithm for n and LAMBDA
    int256 t = 1;
    int256 oldt = 0;
    uint256 r = uint256(_LAMBDA);
    uint256 oldr = uint256(_pp);
    uint256 quotient;

    while (uint256(r) >= sqrt(_pp)) {
      quotient = oldr / r;
      (oldr, r) = (r, oldr - quotient*r);
      (oldt, t) = (t, oldt - int256(quotient)*t);
    }
  // the vectors v1=(a1, b1) and v2=(a2,b2)
    int256[4] memory ab;
    ab[0] = int256(r);
    ab[1] = int256(0 - t);
    ab[2] = int256(oldr);
    ab[3] = 0-oldt;

  //b2*K
    uint[3] memory test;
    (test[0],test[1], test[2]) = multiply256(uint(ab[3]), uint(_k));

  //-b1*k
    uint[3] memory test2;
    (test2[0], test2[1], test2[2]) = multiply256(uint(-ab[1]), uint(_k));
  //c1 and c2
    uint[2] memory c1;
    (c1[0],c1[1]) = bigDivision(uint256 (uint128 (test[0])) << 128 | uint128 (test[1]), uint256(test[2]) + (_pp / 2), _pp);

    uint[2] memory c2;
    (c2[0],c2[1]) = bigDivision(uint256 (uint128 (test2[0])) << 128 | uint128 (test2[1]), uint256(test2[2]) + (_pp / 2), _pp);

  // the decomposition of k in k1 and k2
    int256 k1 = int256((int256(_k) - int256(c1[0]) * int256(ab[0]) - int256(c2[0]) * int256(ab[2])) % int256(_pp));
    int256 k2 = int256((-int256(c1[0]) * int256(ab[1]) - int256(c2[0]) * int256(ab[3])) % int256(_pp));
    if (uint256(abs(k1)) <= (_pp / 2)) {
      k1 = k1;
    } else {
      k1 = int256(uint256(k1) - _pp);
    }
    if (uint256(abs(k2)) <= (_pp / 2)) {
      k2 = k2;
    } else {
      k2 = int256(uint256(k2) - _pp);
    }

    return [k1, k2];
  }

  /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
  /// @param d scalar to multiply
  /// @param x coordinate x of P1
  /// @param y coordinate y of P1
  /// @param a constant of the curve
  /// @param pp the modulus
  /// @return (qx, qy) = d*P in affine coordinates
  function ecMul(
    uint256 d,
    uint256 x,
    uint256 y,
    uint256 a,
    uint256 pp)
  public pure returns(uint256 qx, uint256 qy)
  {
    // Jacobian multiplication
    (uint256 x1, uint256 y1, uint256 z1) = jacMul(
      d,
      x,
      y,
      1,
      a,
      pp);
    // Get back to affine
    (qx, qy) = toAffine(
      x1,
      y1,
      z1,
      pp);
  }

  /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
  /// @param x1 coordinate x of P1
  /// @param y1 coordinate y of P1
  /// @param z1 coordinate z of P1
  /// @param x2 coordinate x of square
  /// @param y2 coordinate y of square
  /// @param z2 coordinate z of square
  /// @param pp the modulus
  /// @return (qx, qy, qz) P1+square in Jacobian
  function jacAdd(
    uint256 x1,
    uint256 y1,
    uint256 z1,
    uint256 x2,
    uint256 y2,
    uint256 z2,
    uint256 pp)
  internal pure returns (uint256 qx, uint256 qy, uint256 qz)
  {
    if ((x1==0)&&(y1==0))
      return (x2, y2, z2);
    if ((x2==0)&&(y2==0))
      return (x1, y1, z1);
    // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5

    uint[4] memory zs; // z1^2, z1^3, z2^2, z2^3
    zs[0] = mulmod(z1, z1, pp);
    zs[1] = mulmod(z1, zs[0], pp);
    zs[2] = mulmod(z2, z2, pp);
    zs[3] = mulmod(z2, zs[2], pp);

    // u1, s1, u2, s2
    zs = [
      mulmod(x1, zs[2], pp),
      mulmod(y1, zs[3], pp),
      mulmod(x2, zs[0], pp),
      mulmod(y2, zs[1], pp)
    ];
    if (zs[0] == zs[2]) {
      if (zs[1] != zs[3])
        revert("Wrong data");
      else {
        revert("Use double instead");
      }
    }
    uint[4] memory hr;
    //h
    hr[0] = addmod(zs[2], pp - zs[0], pp);
    //r
    hr[1] = addmod(zs[3], pp - zs[1], pp);
    //h^2
    hr[2] = mulmod(hr[0], hr[0], pp);
    // h^3
    hr[3] = mulmod(hr[2], hr[0], pp);
    // qx = -h^3  -2u1h^2+r^2
    qx = addmod(mulmod(hr[1], hr[1], pp), pp - hr[3], pp);
    qx = addmod(qx, pp - mulmod(2, mulmod(zs[0], hr[2], pp), pp), pp);
    // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
    qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], pp), pp - qx, pp), pp);
    qy = addmod(qy, pp - mulmod(zs[1], hr[3], pp), pp);
    // qz = h*z1*z2
    qz = mulmod(hr[0], mulmod(z1, z2, pp), pp);
  }

  /// @dev Doubles a points (x, y, z).
  /// @param x coordinate x of P1
  /// @param y coordinate y of P1
  /// @param z coordinate z of P1
  /// @param pp the modulus
  /// @param a the a scalar in the curve equation
  /// @return (qx, qy, qz) 2P in Jacobian
  function jacDouble(
    uint256 x,
    uint256 y,
    uint256 z,
    uint256 a,
    uint256 pp)
  internal pure returns (uint256 qx, uint256 qy, uint256 qz)
  {
    if (z == 0)
      return (x, y, z);
    uint256[3] memory square;
    // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
    // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
    square[0] = mulmod(x, x, pp); //x1^2
    square[1] = mulmod(y, y, pp); //y1^2
    square[2] = mulmod(z, z, pp); //z1^2

    // s
    uint s = mulmod(4, mulmod(x, square[1], pp), pp);
    // m
    uint m = addmod(mulmod(3, square[0], pp), mulmod(a, mulmod(square[2], square[2], pp), pp), pp);
    // t
    uint256 t = addmod(mulmod(m, m, pp), pp - addmod(s, s, pp), pp);
    qx = t;
    // qy = -8*y1^4 + M(S-T)
    qy = addmod(mulmod(m, addmod(s, pp - qx, pp), pp), pp - mulmod(8, mulmod(square[1], square[1], pp), pp), pp);
    // qz = 2*y1*z1
    qz = mulmod(2, mulmod(y, z, pp), pp);
  }

  /// @dev Multiply point (x, y, z) times d.
  /// @param d scalar to multiply
  /// @param x coordinate x of P1
  /// @param y coordinate y of P1
  /// @param z coordinate z of P1
  /// @param a constant of curve
  /// @param pp the modulus
  /// @return (qx, qy, qz) d*P1 in Jacobian
  function jacMul(
    uint256 d,
    uint256 x,
    uint256 y,
    uint256 z,
    uint256 a,
    uint256 pp)
  internal pure returns (uint256 qx, uint256 qy, uint256 qz)
  {
    uint256 remaining = d;
    uint256[3] memory point;
    point[0] = x;
    point[1] = y;
    point[2] = z;
    qx = 0;
    qy = 0;
    qz = 1;

    if (d == 0) {
      return (0, 0, 1);
    }
    // Double and add algorithm
    while (remaining != 0) {
      if ((remaining & 1) != 0) {
        (qx, qy, qz) = jacAdd(
          qx,
          qy,
          qz,
          point[0],
          point[1],
          point[2],
          pp);
      }
      remaining = remaining / 2;
      (point[0], point[1], point[2]) = jacDouble(
        point[0],
        point[1],
        point[2],
        a,
        pp);
    }
  }


  /// @dev Multiplication of a uint256 a and uint256 b. Because in Solidity each variable can not be greater than 256 bits,
  /// this function separates the result of the multiplication in three parts, so the result would be the concatenation of those three
  /// @param _a uint256
  /// @param _b uint256
  /// @return (ab2, ab1, ab0)
  function multiply256(uint256 _a, uint256 _b) internal pure returns (uint256, uint256, uint256) {
    uint256 aM = _a >> 128;
    uint256 am = _a & 2**128-1;
    uint256 bM = _b >> 128;
    uint256 bm = _b & 2**128-1;
    uint256 ab0 = am * bm;
    uint256 ab1 = (ab0 >> 128) + (aM * bm & 2**128-1) + (am * bM & 2**128 - 1);
    uint256 ab2 = (ab1 >> 128) + aM * bM + (aM * bm >> 128) + (am * bM >> 128);
    ab1 &= 2**128 - 1;
    ab0 &= 2**128 - 1;

    return (ab2, ab1, ab0);
  }

  /// @dev Division of an integer of 312 bits by a 256-bit integer
  /// @param _aM the higher 256 bits of the numarator
  /// @param _am the lower 128 bits of the numarator
  /// @param _b the 256-bit denominator
  /// @return q the result of the division and the rest r
  function bigDivision(uint256 _aM, uint256 _am, uint256 _b) internal pure returns (uint256, uint256) {
    uint256 qM = (_aM / _b) << 128;
    uint256 aM = _aM % _b;

    uint256 shift = 0;
    while (_b >> shift > 0) {
      shift++;
    }
    shift = 256 - shift;
    aM = (_aM << shift) + (shift > 128 ? _am << (shift - 128) : _am >> (128 - shift));
    uint256 a0 = (_am << shift) & 2**128-1;
    uint256 b = _b << shift;
    (uint256 b1, uint256 b0) = (b >> 128, b & 2**128-1);

    uint256 rM;
    uint256 q = aM / b1;
    rM = aM % b1;

    uint256 rsub0 = (q & 2**128-1) * b0;
    uint256 rsub21 = (q >> 128) * b0 + (rsub0 >> 128);
    rsub0 &= 2**128-1;

    while (rsub21 > rM || rsub21 == rM && rsub0 > a0) {
      q--;
      a0 += b0;
      rM += b1 + (a0 >> 128);
      a0 &= 2**128-1;
    }

    q += qM;
    uint256 r = (((rM - rsub21) << 128) + _am - rsub0) >> shift;

    return (q, r);
  }

  /// @dev Sqare root of an 256-bit integer
  /// @param _x the integer
  /// @return y the square root of _x
  function  sqrt(uint256 _x) internal pure returns (uint256) {
    uint256 z = (_x + 1) / 2;
    uint256 y = _x;
    while (z < y) {
      y = z;
      z = (_x / z + z) / 2;
    }
    return (y);
  }

  /// @dev Absolute value of a 25-bit integer
  /// @param _x the integer
  /// @return _x if _x>=0 or -_x if not
  function abs(int256 _x) internal pure returns (int256) {
    if (_x >= 0)
    return _x;
    return -_x;
  }
}
