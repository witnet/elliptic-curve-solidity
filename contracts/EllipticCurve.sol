pragma solidity ^0.5.0;


/**
 * @title Elliptic Curve Library
 * @dev Library providing arithmetic operations over elliptic curves.
 * @author Witnet Foundation
 */
contract EllipticCurve {

  /// @dev Modular euclidean inverse of a number (mod p).
  /// @param _x The number
  /// @param _pp The modulus
  /// @return q such that x*q = 1 (mod _pp)
  function invMod(uint256 _x, uint256 _pp) public pure returns (uint256) {
    if (_x == 0 || _x == _pp || _pp == 0) {
      revert("Invalid number");
    }
    uint256 q = 0;
    uint256 newT = 1;
    uint256 r = _pp;
    uint256 newR = _x;
    uint256 t;
    while (newR != 0) {
      t = r / newR;
      (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
      (r, newR) = (newR, r - t * newR );
    }

    return q;
  }

  /// @dev Modular exponentiation, b^e % _pp.
  /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
  /// @param _base base
  /// @param _exp exponent
  /// @param _pp modulus
  /// @return r such that r = b**e (mod _pp)
  function expMod(uint256 _base, uint256 _exp, uint256 _pp) public pure returns (uint256) {
    if (_base == 0)
      return 0;
    if (_exp == 0)
      return 1;
    if (_pp == 0)
      revert("Modulus is zero");
    uint256 r = 1;
    uint256 bit = 2 ** 255;

    assembly {
      for { } gt(bit, 0) { }{
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, bit)))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), _pp)
        bit := div(bit, 16)
      }
    }

    return r;
  }

  /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
  /// @param _x coordinate x
  /// @param _y coordinate y
  /// @param _z coordinate z
  /// @param _pp the modulus
  /// @return (x', y') affine coordinates
  function toAffine(
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _pp)
  public pure returns (uint256, uint256)
  {
    uint256 zInv = invMod(_z, _pp);
    uint256 zInv2 = mulmod(zInv, zInv, _pp);
    uint256 x2 = mulmod(_x, zInv2, _pp);
    uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, _pp), _pp);

    return (x2, y2);
  }

  /// @dev Derives the y coordinate from a compressed-format point x.
  /// @param _prefix parity byte (0x02 even, 0x03 odd)
  /// @param _x coordinate x
  /// @param _aa constant of curve
  /// @param _bb constant of curve
  /// @param _pp the modulus
  /// @return y coordinate y
  function deriveY(
    uint8 _prefix,
    uint256 _x,
    uint256 _aa,
    uint256 _bb,
    uint256 _pp)
  public pure returns (uint256)
  {
    // x^3 + ax + b
    uint256 y2 = addmod(mulmod(_x, mulmod(_x, _x, _pp), _pp), addmod(mulmod(_x, _aa, _pp), _bb, _pp), _pp);
    y2 = expMod(y2, (_pp + 1) / 4, _pp);
    // uint256 cmp = yBit ^ y_ & 1;
    uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : _pp - y2;

    return y;
  }

  /// @dev Check whether point (x,y) is on curve defined by a, b, and _pp.
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _aa constant of curve
  /// @param _bb constant of curve
  /// @param _pp the modulus
  /// @return true if x,y in the curve, false else
  function isOnCurve(
    uint _x,
    uint _y,
    uint _aa,
    uint _bb,
    uint _pp)
  public pure returns (bool)
  {
    if (0 == _x || _x == _pp || 0 == _y || _y == _pp) {
      return false;
    }
    // y^2
    uint lhs = mulmod(_y, _y, _pp);
    // x^3
    uint rhs = mulmod(mulmod(_x, _x, _pp), _x, _pp);
    if (_aa != 0) {
      // x^3 + a*x
      rhs = addmod(rhs, mulmod(_x, _aa, _pp), _pp);
    }
    if (_bb != 0) {
      // x^3 + a*x + b
      rhs = addmod(rhs, _bb, _pp);
    }

    return lhs == rhs;
  }

  /// @dev Calculate inverse (x, -y) of point (x, y).
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _pp the modulus
  /// @return (x, -y)
  function ecInv(
    uint256 _x,
    uint256 _y,
    uint256 _pp)
  public pure returns (uint256, uint256)
  {
    return (_x, (_pp - _y) % _pp);
  }

  /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _x2 coordinate x of P2
  /// @param _y2 coordinate y of P2
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = P1+P2 in affine coordinates
  function ecAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2,
    uint256 _aa,
    uint256 _pp)
    public pure returns(uint256, uint256)
  {
    uint x = 0;
    uint y = 0;
    uint z = 0;
    // Double if x1==x2 else add
    if (_x1==_x2) {
      (x, y, z) = jacDouble(
        _x1,
        _y1,
        1,
        _aa,
        _pp);
    } else {
      (x, y, z) = jacAdd(
        _x1,
        _y1,
        1,
        _x2,
        _y2,
        1,
        _pp);
    }
    // Get back to affine
    return toAffine(
      x,
      y,
      z,
      _pp);
  }

  /// @dev Substract two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _x2 coordinate x of P2
  /// @param _y2 coordinate y of P2
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = P1-P2 in affine coordinates
  function ecSub(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2,
    uint256 _aa,
    uint256 _pp)
  public pure returns(uint256, uint256)
  {
    // invert square
    (uint256 x, uint256 y) = ecInv(_x2, _y2, _pp);
    // P1-square
    return ecAdd(
      _x1,
      _y1,
      x,
      y,
      _aa,
      _pp);
  }

  /// @dev Decomposition of the scalar k in two scalars k1 and k2 with half bit-length, such that k=k1+k2*LAMBDA (mod n)
  /// @param _k the scalar to be decompose
  /// @param _nn the modulus
  /// @param _lambda is a root of the characteristic polynomial of an endomorphism of the curve
  /// @return k1 and k2  such that k=k1+k2*LAMBDA (mod n)
  function decomposeScalar (uint256 _k, uint256 _nn, uint256 _lambda) public pure returns (int256, int256) {
    uint256 k = _k % _nn;
    // Extended Euclidean Algorithm for n and LAMBDA
    int256[2] memory t;
    t[0] = 1;
    t[1] = 0;
    uint256[2] memory r;
    r[0] = uint256(_lambda);
    r[1] = uint256(_nn);

    while (uint256(r[0]) >= _sqrt(_nn)) {
      uint256 quotient = r[1] / r[0];
      (r[1], r[0]) = (r[0], r[1] - quotient*r[0]);
      (t[1], t[0]) = (t[0], t[1] - int256(quotient)*t[0]);
    }
    int256[4] memory ab;

    // the vectors v1=(a1, b1) and v2=(a2,b2)
    ab[0] = int256(r[0]);
    ab[1] = int256(0 - t[0]);
    ab[2] = int256(r[1]);
    ab[3] = 0 - t[1];

    //b2*K
    uint[3] memory test;
    (test[0],test[1], test[2]) = _multiply256(uint(ab[3]), uint(k));

    //-b1*k
    uint[3] memory test2;
    (test2[0], test2[1], test2[2]) = _multiply256(uint(-ab[1]), uint(k));

    //c1 and c2
    uint[2] memory c1;
    (c1[0],c1[1]) = _bigDivision(uint256 (uint128 (test[0])) << 128 | uint128 (test[1]), uint256(test[2]) + (_nn / 2), _nn);
    uint[2] memory c2;
    (c2[0],c2[1]) = _bigDivision(uint256 (uint128 (test2[0])) << 128 | uint128 (test2[1]), uint256(test2[2]) + (_nn / 2), _nn);

    // the decomposition of k in k1 and k2
    int256 k1 = int256((int256(k) - int256(c1[0]) * int256(ab[0]) - int256(c2[0]) * int256(ab[2])) % int256(_nn));
    int256 k2 = int256((-int256(c1[0]) * int256(ab[1]) - int256(c2[0]) * int256(ab[3])) % int256(_nn));
    if (uint256(_abs(k1)) <= (_nn / 2)) {
      k1 = k1;
    } else {
      k1 = int256(uint256(k1) - _nn);
    }
    if (uint256(_abs(k2)) <= (_nn / 2)) {
      k2 = k2;
    } else {
      k2 = int256(uint256(k2) - _nn);
    }

    return (k1, k2);
  }

  /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
  /// @param _k scalar to multiply
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = d*P in affine coordinates
  function ecMul(
    uint256 _k,
    uint256 _x,
    uint256 _y,
    uint256 _aa,
    uint256 _pp)
  public pure returns(uint256, uint256)
  {
    // Jacobian multiplication
    (uint256 x1, uint256 y1, uint256 z1) = jacMul(
      _k,
      _x,
      _y,
      1,
      _aa,
      _pp);
    // Get back to affine
    return toAffine(
      x1,
      y1,
      z1,
      _pp);
  }

  /// @notice Simultaneous multiplication of the form kP + lQ.
  /// @dev Scalars k and l are expected to be decomposed such that k = k1 + k2 λ, and l = l1 + l2 λ,
  /// where λ is specific to the endomorphism of the curve.
  /// @param _scalars An array with the decomposition of k and l values, i.e., [k1, k2, l1, l2]
  /// @param _points An array with the affine coordinates of both P and Q, i.e., [P1, P2, Q1, Q2]
  function ecSimMul(
    int256[4] memory _scalars,
    uint256[4] memory _points,
    uint256 _aa,
    uint256 _beta,
    uint256 _pp)
  public pure returns (uint256, uint256)
  {
    uint256[4] memory wnaf;
    uint256 maxCount = 0;
    uint256 count = 0;

    for (uint j = 0; j<4; j++) {
      (wnaf[j], count) = _wnaf(_scalars[j]);
      if (count > maxCount) {
        maxCount = count;
      }
    }

    (uint256 x, uint256 y, uint256 z) = _simMulWnaf(
      wnaf,
      maxCount,
      _points,
      _aa,
      _beta,
      _pp);

    return toAffine(
      x,
      y,
      z,
      _pp);
  }

  /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _z1 coordinate z of P1
  /// @param _x2 coordinate x of square
  /// @param _y2 coordinate y of square
  /// @param _z2 coordinate z of square
  /// @param _pp the modulus
  /// @return (qx, qy, qz) P1+square in Jacobian
  function jacAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _z1,
    uint256 _x2,
    uint256 _y2,
    uint256 _z2,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    if ((_x1==0)&&(_y1==0))
      return (_x2, _y2, _z2);
    if ((_x2==0)&&(_y2==0))
      return (_x1, _y1, _z1);
    // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5

    uint[4] memory zs; // z1^2, z1^3, z2^2, z2^3
    zs[0] = mulmod(_z1, _z1, _pp);
    zs[1] = mulmod(_z1, zs[0], _pp);
    zs[2] = mulmod(_z2, _z2, _pp);
    zs[3] = mulmod(_z2, zs[2], _pp);

    // u1, s1, u2, s2
    zs = [
      mulmod(_x1, zs[2], _pp),
      mulmod(_y1, zs[3], _pp),
      mulmod(_x2, zs[0], _pp),
      mulmod(_y2, zs[1], _pp)
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
    hr[0] = addmod(zs[2], _pp - zs[0], _pp);
    //r
    hr[1] = addmod(zs[3], _pp - zs[1], _pp);
    //h^2
    hr[2] = mulmod(hr[0], hr[0], _pp);
    // h^3
    hr[3] = mulmod(hr[2], hr[0], _pp);
    // qx = -h^3  -2u1h^2+r^2
    uint256 qx = addmod(mulmod(hr[1], hr[1], _pp), _pp - hr[3], _pp);
    qx = addmod(qx, _pp - mulmod(2, mulmod(zs[0], hr[2], _pp), _pp), _pp);
    // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
    uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], _pp), _pp - qx, _pp), _pp);
    qy = addmod(qy, _pp - mulmod(zs[1], hr[3], _pp), _pp);
    // qz = h*z1*z2
    uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, _pp), _pp);
    return(qx, qy, qz);
  }

  /// @dev Doubles a points (x, y, z).
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _z coordinate z of P1
  /// @param _pp the modulus
  /// @param _aa the a scalar in the curve equation
  /// @return (qx, qy, qz) 2P in Jacobian
  function jacDouble(
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _aa,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    if (_z == 0)
      return (_x, _y, _z);
    uint256[3] memory square;
    // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
    // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
    square[0] = mulmod(_x, _x, _pp); //x1^2
    square[1] = mulmod(_y, _y, _pp); //y1^2
    square[2] = mulmod(_z, _z, _pp); //z1^2

    // s
    uint s = mulmod(4, mulmod(_x, square[1], _pp), _pp);
    // m
    uint m = addmod(mulmod(3, square[0], _pp), mulmod(_aa, mulmod(square[2], square[2], _pp), _pp), _pp);
    // qx
    uint256 qx = addmod(mulmod(m, m, _pp), _pp - addmod(s, s, _pp), _pp);
    // qy = -8*y1^4 + M(S-T)
    uint256 qy = addmod(mulmod(m, addmod(s, _pp - qx, _pp), _pp), _pp - mulmod(8, mulmod(square[1], square[1], _pp), _pp), _pp);
    // qz = 2*y1*z1
    uint256 qz = mulmod(2, mulmod(_y, _z, _pp), _pp);

    return (qx, qy, qz);
  }

  /// @dev Multiply point (x, y, z) times d.
  /// @param _d scalar to multiply
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _z coordinate z of P1
  /// @param _aa constant of curve
  /// @param _pp the modulus
  /// @return (qx, qy, qz) d*P1 in Jacobian
  function jacMul(
    uint256 _d,
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _aa,
    uint256 _pp)
  internal pure  returns (uint256, uint256, uint256)
  {
    uint256 remaining = _d;
    uint256[3] memory point;
    point[0] = _x;
    point[1] = _y;
    point[2] = _z;
    uint256 qx = 0;
    uint256 qy = 0;
    uint256 qz = 1;

    if (_d == 0) {
      return (qx, qy, qz);
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
          _pp);
      }
      remaining = remaining / 2;
      (point[0], point[1], point[2]) = jacDouble(
        point[0],
        point[1],
        point[2],
        _aa,
        _pp);
    }
    return (qx, qy, qz);
  }

  /// @dev Compute the look up table for the simultaneous multiplication (P, 3P,..,Q,3Q,..).
  /// @param _iP the look up table were values will be stored
  /// @param _points the points P and Q to be multiplied
  /// @param _aa constant of the curve
  /// @param _beta constant of the curve (endomorphism)
  /// @param _pp the modulus
  /// @return (qx, qy, qz) d*P1 in Jacobian
  function _lookupSimMul(
    uint256[3][4][4] memory _iP,
    uint256[4] memory _points,
    uint256 _aa,
    uint256 _beta,
    uint256 _pp
  ) private pure
  {
    uint256[3][4] memory iPj;
    uint256[3] memory double;

    // P1 Lookup Table
    iPj = _iP[0];
    iPj[0] = [_points[0], _points[1], 1]; // P1

    (double[0], double[1], double[2]) = jacDouble(
      iPj[0][0],
      iPj[0][1],
      1,
      _aa,
      _pp);
    (iPj[1][0], iPj[1][1], iPj[1][2]) = jacAdd(
      double[0],
      double[1],
      double[2],
      iPj[0][0],
      iPj[0][1],
      iPj[0][2],
      _pp);
    (iPj[2][0], iPj[2][1], iPj[2][2]) = jacAdd(
      double[0],
      double[1],
      double[2],
      iPj[1][0],
      iPj[1][1],
      iPj[1][2],
      _pp);
    (iPj[3][0], iPj[3][1], iPj[3][2]) = jacAdd(
      double[0],
      double[1],
      double[2],
      iPj[2][0],
      iPj[2][1],
      iPj[2][2],
      _pp);

    // P2 Lookup Table
    _iP[1][0] = [mulmod(_beta, _points[0], _pp), _points[1], 1];	// P2

    _iP[1][1] = [mulmod(_beta, iPj[1][0], _pp), iPj[1][1], iPj[1][2]];
    _iP[1][2] = [mulmod(_beta, iPj[2][0], _pp), iPj[2][1], iPj[2][2]];
    _iP[1][3] = [mulmod(_beta, iPj[3][0], _pp), iPj[3][1], iPj[3][2]];

    // Q1 Lookup Table
    iPj = _iP[2];
    iPj[0] = [_points[2], _points[3], 1];
                    	// Q1
    (double[0], double[1], double[2]) = jacDouble(
      iPj[0][0],
      iPj[0][1],
      1,
      _aa,
      _pp);
    (iPj[1][0], iPj[1][1], iPj[1][2]) = jacAdd(
      double[0],
      double[1],
      double[2],
      iPj[0][0],
      iPj[0][1],
      iPj[0][2],
      _pp);
    (iPj[2][0], iPj[2][1], iPj[2][2]) = jacAdd(
      double[0],
      double[1],
      double[2],
      iPj[1][0],
      iPj[1][1],
      iPj[1][2],
      _pp);
    (iPj[3][0], iPj[3][1], iPj[3][2]) = jacAdd(
      double[0],
      double[1],
      double[2],
      iPj[2][0],
      iPj[2][1],
      iPj[2][2],
      _pp);

    // Q2 Lookup Table
    _iP[3][0] = [mulmod(_beta, _points[2], _pp), _points[3], 1];	// P2

    _iP[3][1] = [mulmod(_beta, iPj[1][0], _pp), iPj[1][1], iPj[1][2]];
    _iP[3][2] = [mulmod(_beta, iPj[2][0], _pp), iPj[2][1], iPj[2][2]];
    _iP[3][3] = [mulmod(_beta, iPj[3][0], _pp), iPj[3][1], iPj[3][2]];
  }

  /// @dev WNAF integer representation. Computes the WNAF representation of an integer, and puts the resulting array of coefficients in memory.
  /// @param _k A 256-bit integer
  /// @return (ptr, length) The pointer to the first coefficient, and the total length of the array
  function _wnaf(int256 _k) private pure  returns (uint256, uint256) {
    int sign = _k < 0 ? -1 : int(1);
    uint256 k = uint256(sign * _k);

    uint256 ptr;
    uint256 length = 0;
    assembly
    {
      let ki := 0
      ptr := mload(0x40) // Get free memory pointer
      mstore(0x40, add(ptr, 300)) // Updates free memory pointer to +300 bytes offset
      for { } gt(k, 0) { } { // while k > 0
        if and(k, 1) {  // if k is odd:
          ki := mod(k, 16)
          k := add(sub(k, ki), mul(gt(ki, 8), 16))
          // if sign = 1, store ki; if sign = -1, store 16 - ki
          mstore8(add(ptr, length), add(mul(ki, sign), sub(8, mul(sign, 8))))
        }
        length := add(length, 1)
        k := div(k, 2)
      }
    }

    return (ptr, length);
  }

  /// @dev Compute the simultaneous multiplication with wnaf decomposed scalar.
  /// @param _wnafPointer the decomposed scalars to be multiplied in wnaf form (k1, k2, l1, l2)
  /// @param _points the points P and Q to be multiplied
  /// @param _aa constant of the curve
  /// @param _beta constant of the curve (endomorphism)
  /// @param _pp the modulus
  /// @return (qx, qy, qz) d*P1 in Jacobian
  function _simMulWnaf(
    uint256[4] memory _wnafPointer,
    uint256 _length,
    uint256[4] memory _points,
    uint256 _aa,
    uint256 _beta,
    uint256 _pp)
  private pure  returns (uint256, uint256, uint256)
  {
    uint[3] memory mulPoint;
    uint256[3][4][4] memory iP;
    _lookupSimMul(
      iP,
      _points,
      _aa,
      _beta,
      _pp);

    uint256 i = _length;
    uint256 ki;
    uint256 ptr;
    while (i > 0) {
      i--;

      (mulPoint[0], mulPoint[1], mulPoint[2]) = jacDouble(
        mulPoint[0],
        mulPoint[1],
        mulPoint[2],
        _aa,
        _pp);

      ptr = _wnafPointer[0] + i;
      assembly {
        ki := byte(0, mload(ptr))
      }

      if (ki > 8) {
        (mulPoint[0], mulPoint[1], mulPoint[2]) = jacAdd(
          mulPoint[0],
          mulPoint[1],
          mulPoint[2],
          iP[0][(15 - ki) / 2][0],
          (_pp - iP[0][(15 - ki) / 2][1]) % _pp, iP[0][(15 - ki) / 2][2],
          _pp);
      } else if (ki > 0) {
        (mulPoint[0], mulPoint[1], mulPoint[2]) = jacAdd(
          mulPoint[0],
          mulPoint[1],
          mulPoint[2],
          iP[0][(ki - 1) / 2][0], iP[0][(ki - 1) / 2][1],
          iP[0][(ki - 1) / 2][2],
          _pp);
      }

      ptr = _wnafPointer[1] + i;
      assembly {
        ki := byte(0, mload(ptr))
      }

      if (ki > 8) {
        (mulPoint[0], mulPoint[1], mulPoint[2]) = jacAdd(
          mulPoint[0],
          mulPoint[1],
          mulPoint[2],
          iP[1][(15 - ki) / 2][0],
          (_pp - iP[1][(15 - ki) / 2][1]) % _pp, iP[1][(15 - ki) / 2][2],
          _pp);

      } else if (ki > 0) {
        (mulPoint[0], mulPoint[1], mulPoint[2]) = jacAdd(
          mulPoint[0],
          mulPoint[1],
          mulPoint[2],
          iP[1][(ki - 1) / 2][0],
          iP[1][(ki - 1) / 2][1], iP[1][(ki - 1) / 2][2],
          _pp);
      }

      ptr = _wnafPointer[2] + i;
      assembly {
        ki := byte(0, mload(ptr))
      }

      if (ki > 8) {
        (mulPoint[0], mulPoint[1], mulPoint[2]) = jacAdd(
          mulPoint[0],
          mulPoint[1],
          mulPoint[2],
          iP[2][(15 - ki) / 2][0],
          (_pp - iP[2][(15 - ki) / 2][1]) % _pp, iP[2][(15 - ki) / 2][2],
          _pp);
      } else if (ki > 0) {
        (mulPoint[0], mulPoint[1], mulPoint[2]) = jacAdd(
          mulPoint[0],
          mulPoint[1],
          mulPoint[2],
          iP[2][(ki - 1) / 2][0],
          iP[2][(ki - 1) / 2][1],
          iP[2][(ki - 1) / 2][2],
          _pp);
      }

      ptr = _wnafPointer[3] + i;
      assembly {
        ki := byte(0, mload(ptr))
      }

      if (ki > 8) {
        (mulPoint[0], mulPoint[1], mulPoint[2]) = jacAdd(
          mulPoint[0],
          mulPoint[1],
          mulPoint[2],
          iP[3][(15 - ki) / 2][0],
          (_pp - iP[3][(15 - ki) / 2][1]) % _pp,
          iP[3][(15 - ki) / 2][2],
          _pp);
      } else if (ki > 0) {
        (mulPoint[0], mulPoint[1], mulPoint[2]) = jacAdd(
          mulPoint[0],
          mulPoint[1],
          mulPoint[2],
          iP[3][(ki - 1) / 2][0],
          iP[3][(ki - 1) / 2][1], iP[3][(ki - 1) / 2][2],
          _pp);
      }
    }

    return (mulPoint[0], mulPoint[1], mulPoint[2]);
  }

  /// @dev Multiplication of a uint256 a and uint256 b. Because in Solidity each variable can not be greater than 256 bits,
  /// this function separates the result of the multiplication in three parts, so the result would be the concatenation of those three.
  /// @param _a uint256
  /// @param _b uint256
  /// @return (ab2, ab1, ab0)
  function _multiply256(uint256 _a, uint256 _b) private pure returns (uint256, uint256, uint256) {
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

  /// @dev Division of an integer of 312 bits by a 256-bit integer.
  /// @param _aM the higher 256 bits of the numarator
  /// @param _am the lower 128 bits of the numarator
  /// @param _b the 256-bit denominator
  /// @return q the result of the division and the rest r
  function _bigDivision(uint256 _aM, uint256 _am, uint256 _b) private pure returns (uint256, uint256) {
    uint256 qM = (_aM / _b) << 128;
    uint256 aM = _aM % _b;

    uint256 shift = 0;
    while (_b >> shift > 0) {
      shift++;
    }
    shift = 256 - shift;
    aM = (_aM << shift) + (shift > 128 ? _am << (shift - 128) : _am >> (128 - shift));
    uint256 a0 = (_am << shift) & 2**128-1;
    uint256[2] memory b;

    (b[1], b[0]) = ((_b << shift) >> 128, (_b << shift) & 2**128-1);

    uint256 rM;
    uint256 q = aM / b[1];
    rM = aM % b[1];

    uint256 rsub0 = (q & 2**128-1) * b[0];
    uint256 rsub21 = (q >> 128) * b[0] + (rsub0 >> 128);
    rsub0 &= 2**128-1;

    while (rsub21 > rM || rsub21 == rM && rsub0 > a0) {
      q--;
      a0 += b[0];
      rM += b[1] + (a0 >> 128);
      a0 &= 2**128-1;
    }

    q += qM;
    uint256 r = (((rM - rsub21) << 128) + _am - rsub0) >> shift;

    return (q, r);
  }

  /// @dev Square root of an 256-bit integer.
  /// @param _x the integer
  /// @return y the square root of _x
  function _sqrt(uint256 _x) private pure returns (uint256) {
    uint256 z = (_x + 1) / 2;
    uint256 y = _x;
    while (z < y) {
      y = z;
      z = (_x / z + z) / 2;
    }
    return (y);
  }

  /// @dev Absolute value of a 25-bit integer.
  /// @param _x the integer
  /// @return _x if _x>=0 or -_x if not
  function _abs(int256 _x) private pure returns (int256) {
    if (_x >= 0)
    return _x;
    return -_x;
  }
}
