pragma solidity ^0.5.0;

/**
 * @title Elliptic Curve Library
 * @dev Library providing arithmetic operations over elliptic curves
 * @author Witnet Foundation
 */


contract ScalarDecompose {

  uint256 constant minusLambda = 0xAC9C52B33FA3CF1F5AD9E3FD77ED9BA4A880B9FC8EC739C2E0CFC810B51283CF;
  uint256 constant minusB1 = 0x00000000000000000000000000000000E4437ED6010E88286F547FA90ABFE4C3;
  uint256 constant minusB2 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE8A280AC50774346DD765CDA83DB1562C;
  uint256 constant g1 = 0x00000000000000000000000000003086D221A7D46BCDE86C90E49284EB153DAB;
  uint256 constant g2 = 0x0000000000000000000000000000E4437ED6010E88286F547FA90ABFE4C42212;
  uint256 group = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
  uint256 biggest = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  function ceil(uint a, uint m) public pure returns (uint ) {
    return ((a + m - 1) / m) * m;
  }
  function mul256By256(uint a, uint b)
        internal pure
        returns (uint ab32, uint ab1, uint ab0)
    {
        uint ahi = a >> 128;
        uint alo = a & 2**128-1;
        uint bhi = b >> 128;
        uint blo = b & 2**128-1;
        ab0 = alo * blo;
        ab1 = (ab0 >> 128) + (ahi * blo & 2**128-1) + (alo * bhi & 2**128-1);
        ab32 = (ab1 >> 128) + ahi * bhi + (ahi * blo >> 128) + (alo * bhi >> 128);
        ab1 &= 2**128-1;
        ab0 &= 2**128-1;
    }

  function msb (uint256 x) private pure returns (uint256) {
    require (x > 0);

    uint256 a = 0;
    uint256 b = 255;
    while (a < b) {
      uint256 m = a + b >> 1;
      uint256 t = x >> m;
      if (t == 0) b = m - 1;
      else if (t > 1) a = m + 1;
      else {
        a = m;
        break;
      }
    }

    return a;
  }
  function fromUInt (uint256 x) internal pure returns (uint128) {
    if (x == 0) return (0);
    else {
      uint256 result = x;

      uint256 msb = msb (result);
      result = result + (0x01 << (msb-53));

      result = result & (0xFFFFFFFFFFFFFF << (msb-52));

      return uint128 (result);
    }
  }
  
  function roundedsplitDiv(uint256 num) public view returns(uint256 r1, uint256 r2){
    uint256 c1;
    uint256 c2;
    uint256 t1;
    uint256 t2;
    uint t3;
    (t1, t2, t3) = mul256By256(num, g1);
    c1 = fromUInt(t1 >> 16);
    (t1, t2, t3) = mul256By256(num, g2);
    c2 = fromUInt(t1 >> 16);

    c1 = mulmod(c1, minusB1, group);
    c2 = mulmod(c2, minusB2, group);

    r2 = addmod(c1, c2, group);
 
    r1 = mulmod(r2, minusLambda, group);
    r1 = addmod(r1, num, group);
    return(r1,r2);

  }

}