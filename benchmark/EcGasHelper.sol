// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../contracts/EllipticCurve.sol";
import "../contracts/FastEcMul.sol";

/**
 ** @title Test Helper for the EllipticCurve contract
 ** @dev The aim of this contract is twofold:
 **      - 1. Raise the visibility modifier of contract functions for testing purposes
 **      - 2. Removal of the `pure` modifier to allow gas consumption analysis
 ** @author Witnet Foundation
 */
contract EcGasHelper {
    function _toAffine(
            uint256 _x,
            uint256 _y,
            uint256 _z,
            uint256 _pp
        )
        external
        returns (uint256, uint256)
    {
        return EllipticCurve.toAffine(_x, _y, _z, _pp);
    }

    function _invMod(uint256 _x, uint256 _pp) external returns (uint256) {
        return EllipticCurve.invMod(_x, _pp);
    }

    function _deriveY(
        uint8 _prefix,
        uint256 _x,
        uint256 _aa,
        uint256 _bb,
        uint256 _pp
    ) external returns (uint256) {
        return EllipticCurve.deriveY(_prefix, _x, _aa, _bb, _pp);
    }

    function _isOnCurve(
        uint _x,
        uint _y,
        uint _aa,
        uint _bb,
        uint _pp
    ) external returns (bool) {
        return EllipticCurve.isOnCurve(_x, _y, _aa, _bb, _pp);
    }

    function _ecInv(
        uint256 _x,
        uint256 _y,
        uint256 _pp
    ) external returns (uint256, uint256) {
        return EllipticCurve.ecInv(_x, _y, _pp);
    }

    function _ecAdd(
            uint256 _x1,
            uint256 _y1,
            uint256 _x2,
            uint256 _y2,
            uint256 _aa,
            uint256 _pp
        ) 
        external
        returns (uint256, uint256)
    {
        return EllipticCurve.ecAdd(_x1, _y1, _x2, _y2, _aa, _pp);
    }

    function _ecSub(
            uint256 _x1,
            uint256 _y1,
            uint256 _x2,
            uint256 _y2,
            uint256 _aa,
            uint256 _pp
        ) 
        external 
        returns (uint256, uint256) 
    {
        return EllipticCurve.ecSub(_x1, _y1, _x2, _y2, _aa, _pp);
    }

    function _ecMul(
            uint256 _k,
            uint256 _x,
            uint256 _y,
            uint256 _aa,
            uint256 _pp
        ) 
        external 
        returns (uint256, uint256) 
    {
        return EllipticCurve.ecMul(_k, _x, _y, _aa, _pp);
    }

    function _decomposeScalar(
            uint256 _k,
            uint256 _nn,
            uint256 _lambda
        ) 
        external 
        returns (int256, int256) 
    {
        return FastEcMul.decomposeScalar(_k, _nn, _lambda);
    }

    function _ecSimMul(
            int256[4] calldata _scalars,
            uint256[4] calldata _points,
            uint256 _aa,
            uint256 _beta,
            uint256 _pp
        ) 
        external 
        returns (uint256, uint256)
    {
        return FastEcMul.ecSimMul(_scalars, _points, _aa, _beta, _pp);
    }
}
