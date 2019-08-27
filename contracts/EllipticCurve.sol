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
  /// @param _n the modulus
  /// @param _LAMBDA is a root of the characteristic polynomial of an endomorphism of the curve
  /// @return k1 and k2  such that k=k1+k2*LAMBDA (mod n)
  function scalarDecomposition (uint256 _k, uint256 _n, uint256 _LAMBDA) public pure returns (int256[2] memory) {
  // Extended Euclidean Algorithm for n and LAMBDA
    int256[2] memory t;
    t[0] = 1;
    t[1] = 0;
    uint256[2] memory r;
    r[0] = uint256(_LAMBDA);
    r[1] = uint256(_n);

    uint256 quotient;

    while (uint256(r[0]) >= sqrt(_n)) {
      quotient = r[1] / r[0];
      (r[1], r[0]) = (r[0], r[1] - quotient*r[0]);
      (t[1], t[0]) = (t[0], t[1] - int256(quotient)*t[0]);
    }
    int256[4] memory ab;
  // the vectors v1=(a1, b1) and v2=(a2,b2)
    ab[0] = int256(r[0]);
    ab[1] = int256(0 - t[0]);
    ab[2] = int256(r[1]);
    ab[3] = 0-t[1];

  //b2*K
    uint[3] memory test;
    (test[0],test[1], test[2]) = multiply256(uint(ab[3]), uint(_k));

  //-b1*k
    uint[3] memory test2;
    (test2[0], test2[1], test2[2]) = multiply256(uint(-ab[1]), uint(_k));
  //c1 and c2
    uint[2] memory c1;
    (c1[0],c1[1]) = bigDivision(uint256 (uint128 (test[0])) << 128 | uint128 (test[1]), uint256(test[2]) + (_n / 2), _n);

    uint[2] memory c2;
    (c2[0],c2[1]) = bigDivision(uint256 (uint128 (test2[0])) << 128 | uint128 (test2[1]), uint256(test2[2]) + (_n / 2), _n);

  // the decomposition of k in k1 and k2
    int256 k1 = int256((int256(_k) - int256(c1[0]) * int256(ab[0]) - int256(c2[0]) * int256(ab[2])) % int256(_n));
    int256 k2 = int256((-int256(c1[0]) * int256(ab[1]) - int256(c2[0]) * int256(ab[3])) % int256(_n));
    if (uint256(abs(k1)) <= (_n / 2)) {
      k1 = k1;
    } else {
      k1 = int256(uint256(k1) - _n);
    }
    if (uint256(abs(k2)) <= (_n / 2)) {
      k2 = k2;
    } else {
      k2 = int256(uint256(k2) - _n);
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
  
  function _lookup_sim_mul(
    uint256[3][4][4] memory iP, 
    uint256[4] memory P_Q,
    uint256 a,
    uint256 pp
  ) internal pure
  {
    uint256 p = pp;
    uint256 beta = 0x7ae96a2b657c07106e64479eac3434e99cf0497512f58995c1396c28719501ee;

    uint256[3][4] memory iPj;
    uint256[3] memory double;

    // P1 Lookup Table
    iPj = iP[0];
    iPj[0] = [P_Q[0], P_Q[1], 1];  						// P1

    (double[0], double[1], double[2]) = jacDouble(iPj[0][0], iPj[0][1], 1, a, pp);
    (iPj[1][0], iPj[1][1], iPj[1][2]) = jacAdd(double[0], double[1], double[2], iPj[0][0], iPj[0][1], iPj[0][2], pp);
    (iPj[2][0], iPj[2][1], iPj[2][2]) = jacAdd(double[0], double[1], double[2], iPj[1][0], iPj[1][1], iPj[1][2], pp);
    (iPj[3][0], iPj[3][1], iPj[3][2]) = jacAdd(double[0], double[1], double[2], iPj[2][0], iPj[2][1], iPj[2][2], pp);

    // P2 Lookup Table
    iP[1][0] = [mulmod(beta, P_Q[0], p), P_Q[1], 1];	// P2

    iP[1][1] = [mulmod(beta, iPj[1][0], p), iPj[1][1], iPj[1][2]];
    iP[1][2] = [mulmod(beta, iPj[2][0], p), iPj[2][1], iPj[2][2]];
    iP[1][3] = [mulmod(beta, iPj[3][0], p), iPj[3][1], iPj[3][2]];

    // Q1 Lookup Table
    iPj = iP[2];
    iPj[0] = [P_Q[2], P_Q[3], 1];   
                    	// Q1
    (double[0], double[1], double[2]) = jacDouble(iPj[0][0], iPj[0][1], 1, a, pp);
    (iPj[1][0], iPj[1][1], iPj[1][2]) = jacAdd(double[0], double[1], double[2], iPj[0][0], iPj[0][1], iPj[0][2], pp);
    (iPj[2][0], iPj[2][1], iPj[2][2]) = jacAdd(double[0], double[1], double[2], iPj[1][0], iPj[1][1], iPj[1][2], pp);
    (iPj[3][0], iPj[3][1], iPj[3][2]) = jacAdd(double[0], double[1], double[2], iPj[2][0], iPj[2][1], iPj[2][2], pp);

    // Q2 Lookup Table
    iP[3][0] = [mulmod(beta, P_Q[2], p), P_Q[3], 1];	// P2

    iP[3][1] = [mulmod(beta, iPj[1][0], p), iPj[1][1], iPj[1][2]];
    iP[3][2] = [mulmod(beta, iPj[2][0], p), iPj[2][1], iPj[2][2]];
    iP[3][3] = [mulmod(beta, iPj[3][0], p), iPj[3][1], iPj[3][2]];
  }

  /// @notice Computes the WNAF representation of an integer, and puts the resulting array of coefficients in memory
  /// @param d A 256-bit integer
  /// @return (ptr, length) The pointer to the first coefficient, and the total length of the array
  function _wnaf(int256 d) internal pure  returns (uint256 ptr, uint256 length) {

    int sign = d < 0 ? -1 : int(1);
    uint256 k = uint256(sign * d);

    length = 0;
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
    //log3(ptr, 1, 0xfabadaacabada, d, length)    
    }

    return (ptr, length);
  }
  function toUint(int256 a)public pure  returns(uint256 num) {
    num = uint256(a);
  }
  function eqJacobian(
    uint256[3] memory P, 
    uint256[3] memory Q,
    uint256 pp
  ) internal pure returns(bool) {
    uint256 p = pp;

    uint256 Qz = Q[2];
    uint256 Pz = P[2];
    if(Pz == 0){
      return Qz == 0;   // P and Q are both zero.
    } else if(Qz == 0){
      return false;       // Q is zero but P isn't.
    }

    // Now we're sure none of them is zero

    uint256 Q_z_squared = mulmod(Qz, Qz, p);
    uint256 P_z_squared = mulmod(Pz, Pz, p);
    if (mulmod(P[0], Q_z_squared, p) != mulmod(Q[0], P_z_squared, p)){
      return false;
    }

    uint256 Q_z_cubed = mulmod(Q_z_squared, Qz, p);
    uint256 P_z_cubed = mulmod(P_z_squared, Pz, p);
    return mulmod(P[1], Q_z_cubed, p) == mulmod(Q[1], P_z_cubed, p);
  }

  /// @notice Simultaneous multiplication of the form kP + lQ. 
  /// @dev Scalars k and l are expected to be decomposed such that k = k1 + k2 λ, and l = l1 + l2 λ,
  /// where λ is specific to the endomorphism of the curve
  /// @param k_l An array with the decomposition of k and l values, i.e., [k1, k2, l1, l2]
  /// @param P_Q An array with the affine coordinates of both P and Q, i.e., [P1, P2, Q1, Q2]
  function _sim_mul(
    int256[4] memory k_l, 
    uint256[4] memory P_Q,
    uint256 a,
    uint256 pp
  ) public pure returns (uint[3] memory Q) {

    /*require(
      is_on_curve(P_Q[0], P_Q[1]) && is_on_curve(P_Q[2], P_Q[3]), 
    	"Invalid points"
  	);*/

    uint256[4] memory wnaf;
    uint256 max_count = 0;
    uint256 count = 0;        

    for (uint j = 0; j<4; j++){
      (wnaf[j], count) = _wnaf(k_l[j]);
      if (count > max_count){
        max_count = count;
      }
    }

    Q = _sim_mul_wnaf(wnaf, max_count, P_Q, a, pp);
  }

  function _sim_mul_wnaf(
    uint256[4] memory wnaf_ptr, 
    uint256 length, 
    uint256[4] memory P_Q,
    uint256 a,
    uint256 pp
  ) internal pure  returns (uint[3] memory Q) {
    uint256[3][4][4] memory iP;
    _lookup_sim_mul(iP, P_Q, a, pp);

    uint256 i = length;
    uint256 ki;
    uint256 ptr;
    while (i > 0) {
      i--;

      (Q[0], Q[1], Q[2]) = jacDouble(Q[0], Q[1], Q[2], a, pp);

      ptr = wnaf_ptr[0] + i;
      assembly {
        ki := byte(0, mload(ptr))
      }

      if (ki > 8) {
        (Q[0], Q[1], Q[2]) = jacAdd(Q[0], Q[1], Q[2], iP[0][(15 - ki) / 2][0], (pp - iP[0][(15 - ki) / 2][1]) % pp, iP[0][(15 - ki) / 2][2], pp);
      } else if (ki > 0) {
        (Q[0], Q[1], Q[2]) = jacAdd(Q[0], Q[1], Q[2], iP[0][(ki - 1) / 2][0], iP[0][(ki - 1) / 2][1], iP[0][(ki - 1) / 2][2], pp);
      }

      ptr = wnaf_ptr[1] + i;
      assembly {
        ki := byte(0, mload(ptr))
      }

      if (ki > 8) {
        (Q[0], Q[1], Q[2]) = jacAdd(Q[0], Q[1], Q[2], iP[1][(15 - ki) / 2][0], (pp - iP[1][(15 - ki) / 2][1]) % pp, iP[1][(15 - ki) / 2][2], pp);

      } else if (ki > 0) {
        (Q[0], Q[1], Q[2]) = jacAdd(Q[0], Q[1], Q[2], iP[1][(ki - 1) / 2][0], iP[1][(ki - 1) / 2][1], iP[1][(ki - 1) / 2][2], pp);
      }

      ptr = wnaf_ptr[2] + i;
      assembly {
        ki := byte(0, mload(ptr))
      }

      if (ki > 8) {
        (Q[0], Q[1], Q[2]) = jacAdd(Q[0], Q[1], Q[2], iP[2][(15 - ki) / 2][0], (pp - iP[2][(15 - ki) / 2][1]) % pp, iP[2][(15 - ki) / 2][2], pp);
      } else if (ki > 0) {
        (Q[0], Q[1], Q[2]) = jacAdd(Q[0], Q[1], Q[2], iP[2][(ki - 1) / 2][0], iP[2][(ki - 1) / 2][1], iP[2][(ki - 1) / 2][2], pp);
      }

      ptr = wnaf_ptr[3] + i;
      assembly {
        ki := byte(0, mload(ptr))
      }

      if (ki > 8) {
        (Q[0], Q[1], Q[2]) = jacAdd(Q[0], Q[1], Q[2], iP[3][(15 - ki) / 2][0], (pp - iP[3][(15 - ki) / 2][1]) % pp, iP[3][(15 - ki) / 2][2], pp);
      } else if (ki > 0) {
        (Q[0], Q[1], Q[2]) = jacAdd(Q[0], Q[1], Q[2], iP[3][(ki - 1) / 2][0], iP[3][(ki - 1) / 2][1], iP[3][(ki - 1) / 2][2], pp);
      } 
    }
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
