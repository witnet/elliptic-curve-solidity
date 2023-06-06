// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EllipticCurve.sol";

/**
 ** @title Fast Elliptic Curve Multiplication Library
 ** @dev Library providing the following speed ups to an elliptic curve multiplication operation.
 **      - wNAF scalar representation
 **      - scalar decomposition through endomorphism
 ** This library does not check whether the inserted points belong to the curve
 ** `isOnCurve` function should be used by the library user to check the aforementioned statement.
 ** @author Witnet Foundation
 **/
library FastEcMul {
    // Pre-computed constant for 2 ** 128 - 1
    uint256 private constant U128_MAX = 340282366920938463463374607431768211455;

    /// @dev Decomposition of the scalar k in two scalars k1 and k2 with half bit-length, such that k=k1+k2*LAMBDA (mod n)
    /// @param _k the scalar to be decompose
    /// @param _nn the modulus
    /// @param _lambda is a root of the characteristic polynomial of an endomorphism of the curve
    /// @return k1 and k2  such that k=k1+k2*LAMBDA (mod n)
    function decomposeScalar(
            uint256 _k,
            uint256 _nn,
            uint256 _lambda
        ) 
        internal pure 
        returns (int256, int256) 
    {
        uint256 k = _k % _nn;
        // Extended Euclidean Algorithm for n and LAMBDA
        int256[2] memory t;
        t[0] = 1;
        t[1] = 0;
        uint256[2] memory r;
        r[0] = uint256(_lambda);
        r[1] = uint256(_nn);

        // Loop while `r[0] >= sqrt(_nn)`
        // Or in other words, `r[0] * r[0] >= _nn`
        // When `r[0] >= 2**128`, `r[0] * r[0]` will overflow so we must check that before
        while ((r[0] >= 2 ** 128) || (r[0] * r[0] >= _nn)) {
            uint256 quotient = r[1] / r[0];
            (r[1], r[0]) = (r[0], r[1] - quotient * r[0]);
            (t[1], t[0]) = (t[0], t[1] - int256(quotient) * t[0]);
        }
        int256[4] memory ab;

        // the vectors v1=(a1, b1) and v2=(a2,b2)
        ab[0] = int256(r[0]);
        ab[1] = int256(-t[0]);
        ab[2] = int256(r[1]);
        ab[3] = int256(-t[1]);

        //b2*K
        uint[3] memory test;
        (test[0], test[1], test[2]) = _multiply256(uint(ab[3]), uint(k));

        //-b1*k
        uint[3] memory test2;
        (test2[0], test2[1], test2[2]) = _multiply256(uint(-ab[1]), uint(k));

        //c1 and c2
        uint[2] memory c1;
        (c1[0], c1[1]) = _bigDivision(
            (uint256(uint128(test[0])) << 128) | uint128(test[1]),
            uint256(test[2]) + (_nn / 2),
            _nn
        );
        uint[2] memory c2;
        (c2[0], c2[1]) = _bigDivision(
            (uint256(uint128(test2[0])) << 128) | uint128(test2[1]),
            uint256(test2[2]) + (_nn / 2),
            _nn
        );

        // the decomposition of k in k1 and k2
        int256 k1 = int256(
            (int256(k) -
                int256(c1[0]) *
                int256(ab[0]) -
                int256(c2[0]) *
                int256(ab[2])) % int256(_nn)
        );
        int256 k2 = int256(
            (-int256(c1[0]) * int256(ab[1]) - int256(c2[0]) * int256(ab[3])) %
                int256(_nn)
        );
        if (uint256(_abs(k1)) > (_nn / 2)) {
            k1 = int256(uint256(k1) - _nn);
        }
        if (uint256(_abs(k2)) > (_nn / 2)) {
            k2 = int256(uint256(k2) - _nn);
        }

        return (k1, k2);
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
            uint256 _pp
        ) 
        internal pure 
        returns (uint256, uint256) 
    {
        uint256[4] memory wnaf;
        uint256 maxCount = 0;
        uint256 count = 0;

        for (uint j = 0; j < 4; j++) {
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
            _pp
        );

        return EllipticCurve.toAffine(x, y, z, _pp);
    }

    /// @dev Compute the look up table for the simultaneous multiplication (P, 3P,..,Q,3Q,..).
    /// @param _iP the look up table were values will be stored
    /// @param _points the points P and Q to be multiplied
    /// @param _aa constant of the curve
    /// @param _beta constant of the curve (endomorphism)
    /// @param _pp the modulus
    function _lookupSimMul(
            uint256[3][4][4] memory _iP,
            uint256[4] memory _points,
            uint256 _aa,
            uint256 _beta,
            uint256 _pp
        ) 
        private pure 
    {
        uint256[3][4] memory iPj;
        uint256[3] memory double;

        // P1 Lookup Table
        iPj = _iP[0];
        iPj[0] = [_points[0], _points[1], 1]; // P1

        (double[0], double[1], double[2]) = EllipticCurve.jacDouble(
            iPj[0][0],
            iPj[0][1],
            1,
            _aa,
            _pp
        );
        (iPj[1][0], iPj[1][1], iPj[1][2]) = EllipticCurve.jacAdd(
            double[0],
            double[1],
            double[2],
            iPj[0][0],
            iPj[0][1],
            iPj[0][2],
            _pp
        );
        (iPj[2][0], iPj[2][1], iPj[2][2]) = EllipticCurve.jacAdd(
            double[0],
            double[1],
            double[2],
            iPj[1][0],
            iPj[1][1],
            iPj[1][2],
            _pp
        );
        (iPj[3][0], iPj[3][1], iPj[3][2]) = EllipticCurve.jacAdd(
            double[0],
            double[1],
            double[2],
            iPj[2][0],
            iPj[2][1],
            iPj[2][2],
            _pp
        );

        // P2 Lookup Table
        _iP[1][0] = [mulmod(_beta, _points[0], _pp), _points[1], 1]; // P2

        _iP[1][1] = [mulmod(_beta, iPj[1][0], _pp), iPj[1][1], iPj[1][2]];
        _iP[1][2] = [mulmod(_beta, iPj[2][0], _pp), iPj[2][1], iPj[2][2]];
        _iP[1][3] = [mulmod(_beta, iPj[3][0], _pp), iPj[3][1], iPj[3][2]];

        // Q1 Lookup Table
        iPj = _iP[2];
        iPj[0] = [_points[2], _points[3], 1]; // Q1
        (double[0], double[1], double[2]) = EllipticCurve.jacDouble(
            iPj[0][0],
            iPj[0][1],
            1,
            _aa,
            _pp
        );
        (iPj[1][0], iPj[1][1], iPj[1][2]) = EllipticCurve.jacAdd(
            double[0],
            double[1],
            double[2],
            iPj[0][0],
            iPj[0][1],
            iPj[0][2],
            _pp
        );
        (iPj[2][0], iPj[2][1], iPj[2][2]) = EllipticCurve.jacAdd(
            double[0],
            double[1],
            double[2],
            iPj[1][0],
            iPj[1][1],
            iPj[1][2],
            _pp
        );
        (iPj[3][0], iPj[3][1], iPj[3][2]) = EllipticCurve.jacAdd(
            double[0],
            double[1],
            double[2],
            iPj[2][0],
            iPj[2][1],
            iPj[2][2],
            _pp
        );

        // Q2 Lookup Table
        _iP[3][0] = [mulmod(_beta, _points[2], _pp), _points[3], 1]; // P2

        _iP[3][1] = [mulmod(_beta, iPj[1][0], _pp), iPj[1][1], iPj[1][2]];
        _iP[3][2] = [mulmod(_beta, iPj[2][0], _pp), iPj[2][1], iPj[2][2]];
        _iP[3][3] = [mulmod(_beta, iPj[3][0], _pp), iPj[3][1], iPj[3][2]];
    }

    /// @dev WNAF integer representation. Computes the WNAF representation of an integer, and puts the resulting array of coefficients in memory.
    /// @param _k A 256-bit integer
    /// @return (ptr, length) The pointer to the first coefficient, and the total length of the array
    function _wnaf(int256 _k) private pure returns (uint256, uint256) {
        int sign = _k < 0 ? -1 : int(1);
        uint256 k = uint256(sign * _k);

        uint256 ptr;
        uint256 length = 0;
        assembly {
            let ki := 0
            ptr := mload(0x40) // Get free memory pointer
            mstore(0x40, add(ptr, 300)) // Updates free memory pointer to +300 bytes offset
            for {

            } gt(k, 0) {

            } {
                // while k > 0
                if and(k, 1) {
                    // if k is odd:
                    ki := mod(k, 16)
                    k := add(sub(k, ki), mul(gt(ki, 8), 16))
                    // if sign = 1, store ki; if sign = -1, store 16 - ki
                    mstore8(
                        add(ptr, length),
                        add(mul(ki, sign), sub(8, mul(sign, 8)))
                    )
                }
                length := add(length, 1)
                k := div(k, 2)
            }
        }

        return (ptr, length);
    }

    /// @dev Compute the simultaneous multiplication with wnaf decomposed scalar.
    /// @param _wnafPointer the decomposed scalars to be multiplied in wnaf form (k1, k2, l1, l2)
    /// @param  _length the length of the WNAF representation array
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
            uint256 _pp
        ) 
        private pure 
        returns (uint256, uint256, uint256) 
    {
        uint[3] memory mulPoint;
        uint256[3][4][4] memory iP;
        _lookupSimMul(iP, _points, _aa, _beta, _pp);

        uint256 ki;
        uint256 ptr;
        while (_length > 0) {
            _length--;

            (mulPoint[0], mulPoint[1], mulPoint[2]) = EllipticCurve.jacDouble(
                mulPoint[0],
                mulPoint[1],
                mulPoint[2],
                _aa,
                _pp
            );

            ptr = _wnafPointer[0] + _length;
            assembly {
                ki := byte(0, mload(ptr))
            }

            if (ki > 8) {
                (mulPoint[0], mulPoint[1], mulPoint[2]) = EllipticCurve.jacAdd(
                    mulPoint[0],
                    mulPoint[1],
                    mulPoint[2],
                    iP[0][(15 - ki) / 2][0],
                    (_pp - iP[0][(15 - ki) / 2][1]) % _pp,
                    iP[0][(15 - ki) / 2][2],
                    _pp
                );
            } else if (ki > 0) {
                (mulPoint[0], mulPoint[1], mulPoint[2]) = EllipticCurve.jacAdd(
                    mulPoint[0],
                    mulPoint[1],
                    mulPoint[2],
                    iP[0][(ki - 1) / 2][0],
                    iP[0][(ki - 1) / 2][1],
                    iP[0][(ki - 1) / 2][2],
                    _pp
                );
            }

            ptr = _wnafPointer[1] + _length;
            assembly {
                ki := byte(0, mload(ptr))
            }

            if (ki > 8) {
                (mulPoint[0], mulPoint[1], mulPoint[2]) = EllipticCurve.jacAdd(
                    mulPoint[0],
                    mulPoint[1],
                    mulPoint[2],
                    iP[1][(15 - ki) / 2][0],
                    (_pp - iP[1][(15 - ki) / 2][1]) % _pp,
                    iP[1][(15 - ki) / 2][2],
                    _pp
                );
            } else if (ki > 0) {
                (mulPoint[0], mulPoint[1], mulPoint[2]) = EllipticCurve.jacAdd(
                    mulPoint[0],
                    mulPoint[1],
                    mulPoint[2],
                    iP[1][(ki - 1) / 2][0],
                    iP[1][(ki - 1) / 2][1],
                    iP[1][(ki - 1) / 2][2],
                    _pp
                );
            }

            ptr = _wnafPointer[2] + _length;
            assembly {
                ki := byte(0, mload(ptr))
            }

            if (ki > 8) {
                (mulPoint[0], mulPoint[1], mulPoint[2]) = EllipticCurve.jacAdd(
                    mulPoint[0],
                    mulPoint[1],
                    mulPoint[2],
                    iP[2][(15 - ki) / 2][0],
                    (_pp - iP[2][(15 - ki) / 2][1]) % _pp,
                    iP[2][(15 - ki) / 2][2],
                    _pp
                );
            } else if (ki > 0) {
                (mulPoint[0], mulPoint[1], mulPoint[2]) = EllipticCurve.jacAdd(
                    mulPoint[0],
                    mulPoint[1],
                    mulPoint[2],
                    iP[2][(ki - 1) / 2][0],
                    iP[2][(ki - 1) / 2][1],
                    iP[2][(ki - 1) / 2][2],
                    _pp
                );
            }

            ptr = _wnafPointer[3] + _length;
            assembly {
                ki := byte(0, mload(ptr))
            }

            if (ki > 8) {
                (mulPoint[0], mulPoint[1], mulPoint[2]) = EllipticCurve.jacAdd(
                    mulPoint[0],
                    mulPoint[1],
                    mulPoint[2],
                    iP[3][(15 - ki) / 2][0],
                    (_pp - iP[3][(15 - ki) / 2][1]) % _pp,
                    iP[3][(15 - ki) / 2][2],
                    _pp
                );
            } else if (ki > 0) {
                (mulPoint[0], mulPoint[1], mulPoint[2]) = EllipticCurve.jacAdd(
                    mulPoint[0],
                    mulPoint[1],
                    mulPoint[2],
                    iP[3][(ki - 1) / 2][0],
                    iP[3][(ki - 1) / 2][1],
                    iP[3][(ki - 1) / 2][2],
                    _pp
                );
            }
        }

        return (mulPoint[0], mulPoint[1], mulPoint[2]);
    }

    /// @dev Multiplication of a uint256 a and uint256 b. Because in Solidity each variable can not be greater than 256 bits,
    /// this function separates the result of the multiplication in three parts, so the result would be the concatenation of those three.
    /// @param _a uint256
    /// @param _b uint256
    /// @return (ab2, ab1, ab0)
    function _multiply256(
            uint256 _a,
            uint256 _b
        ) 
        private pure 
        returns (uint256, uint256, uint256) 
    {
        uint256 aM = _a >> 128;
        uint256 am = _a & U128_MAX;
        uint256 bM = _b >> 128;
        uint256 bm = _b & U128_MAX;
        uint256 ab0 = am * bm;
        uint256 ab1 = (ab0 >> 128) +
            ((aM * bm) & U128_MAX) +
            ((am * bM) & U128_MAX);
        uint256 ab2 = (ab1 >> 128) +
            aM *
            bM +
            ((aM * bm) >> 128) +
            ((am * bM) >> 128);
        ab1 &= U128_MAX;
        ab0 &= U128_MAX;

        return (ab2, ab1, ab0);
    }

    /// @dev Division of an integer of 312 bits by a 256-bit integer.
    /// @param _aM the higher 256 bits of the numarator
    /// @param _am the lower 128 bits of the numarator
    /// @param _b the 256-bit denominator
    /// @return q the result of the division and the rest r
    function _bigDivision(
            uint256 _aM,
            uint256 _am,
            uint256 _b
        ) 
        private pure 
        returns (uint256, uint256) 
    {
        uint256 aM = _aM % _b;

        uint256 shift = 0;
        while (_b >> shift > 0) {
            shift++;
        }
        shift = 256 - shift;
        aM =
            (_aM << shift) +
            (shift > 128 ? _am << (shift - 128) : _am >> (128 - shift));
        uint256 a0 = (_am << shift) & U128_MAX;

        (uint256 b1, uint256 b0) = (
            (_b << shift) >> 128,
            (_b << shift) & U128_MAX
        );

        uint256 rM;
        uint256 q = aM / b1;
        rM = aM % b1;

        uint256 rsub0 = (q & U128_MAX) * b0;
        uint256 rsub21 = (q >> 128) * b0 + (rsub0 >> 128);
        rsub0 &= U128_MAX;

        while (rsub21 > rM || (rsub21 == rM && rsub0 > a0)) {
            q--;
            a0 += b0;
            rM += b1 + (a0 >> 128);
            a0 &= U128_MAX;
        }

        uint256 r = (((rM - rsub21) << 128) + _am - rsub0) >> shift;

        //  `_aM / _b` is qM from the original algorithm, inlined here to reduce stack usage
        return (q + _aM / _b, r);
    }

    /// @dev Absolute value of a 25-bit integer.
    /// @param _x the integer
    /// @return _x if _x>=0 or -_x if not
    function _abs(int256 _x) private pure returns (int256) {
        if (_x >= 0) {
            return _x;
        }
        return -_x;
    }
}
