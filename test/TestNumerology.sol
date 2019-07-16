pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "../contracts/EllipticCurve.sol";

contract TestNumerology is EllipticCurve {
  uint256 pp = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint256 q = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

  function testSim_Mul_1() public {


    int256[4] memory k_l = [int256(-89243190524605339210527649141408088119), int256(-53877858828609620138203152946894934485), int256(-185204247857117235934281322466442848518), int256(-7585701889390054782280085152653861472)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0xc6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5, 0x1ae168fea63dc339a3c58419466ceaeef7f632653266d0e1236431a950cfe52a];
    
    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0x7635e27fba8e1f779dcfdde1b1eacbe0571fbe39ecf6056d29ba4bd3ef5e22f2, 0x197888e5cec769ac2f1eb65dbcbc0e49c00a8cdf01f8030d8286b68c1933fb18, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");

  }
  function testSim_Mul_2() public {

    int256[4] memory k_l = [int256(214823561579703732191288684685541817637229497614098203296057), int256(328478121366914896447265557982456186031632316080993096171520), int256(0x01), int256(0)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8];
    
    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0x5CBDF0646E5DB4EAA398F365F2EA7A0E3D419B7E0330E39CE92BDDEDCAC4F9BC, 0x951435BF45DAA69F5CE8729279E5AB2457EC2F47EC02184A5AF7D9D6F78D9755, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");
  }
  function testSim_Mul_3() public {

    int256[4] memory k_l = [int256(214823561579703732191288684685541817637229497614098203296057), int256(328478121366914896447265557982456186031632316080993096171520), int256(0x05), int256(0)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8];
    
    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0xF9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9, 0xC77084F09CD217EBF01CC819D5C80CA99AFF5666CB3DDCE4934602897B4715BD, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");
  }
  function testSim_Mul_4() public {

    int256[4] memory k_l = [int256(214823561579703732191288684685541817637229497614098203296057), int256(328478121366914896447265557982456186031632316080993096171520), int256(0x06), int256(0)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8];
    
    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0xC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5, 0xE51E970159C23CC65C3A7BE6B99315110809CD9ACD992F1EDC9BCE55AF301705, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");
  }

  function testSim_Mul_5() public {

    int256[4] memory k_l = [int256(53705890394925933047822171171385454409307374403524550824016), int256(82119530341728724111816389495614046507908079020248274042880), int256(107411780789851866095644342342770908818614748807049101648032), int256(164239060683457448223632778991228093015816158040496548085760)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8];
    
    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0xE24CE4BEEE294AA6350FAA67512B99D388693AE4E7F53D19882A6EA169FC1CE1, 0x8B71E83545FC2B5872589F99D948C03108D36797C4DE363EBD3FF6A9E1A95B10, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");
  
  }
  function testSim_Mul_6() public {

    int256[4] memory k_l = [int256(115792089237316192414413617141653525355592536591341038205703945387627440435761), int256(115792089237316193627882036006667504967392792946572138803060540036168056979777), int256(107411780789851866095644342342770908818614748807049101648033), int256(164239060683457448223632778991228093015816158040496548085760)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8];
    
    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0xA6B594B38FB3E77C6EDF78161FADE2041F4E09FD8497DB776E546C41567FEB3C, 0x71444009192228730CD8237A490FEBA2AFE3D27D7CC1136BC97E439D13330D55, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.notEqual(affine[0], expected[0], "Not equal x");
    Assert.notEqual(affine[1], expected[1], "Not equal y");
  }
  function testSim_Mul_7() public {

    int256[4] memory k_l = [int256(53705890394925933047822171171385454409307374403524550824016), int256(82119530341728724111816389495614046507908079020248274042880), int256(107411780789851866095644342342770908818614748807049101648032), int256(164239060683457448223632778991228093015816158040496548085760)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8];
    
    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0xF24CE4BEEE294AA6350FAA67512B99D388693AE4E7F53D19882A6EA169FC1CE1, 0x9B71E83545FC2B5872589F99D948C03108D36797C4DE363EBD3FF6A9E1A95B10, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.notEqual(affine[0], expected[0], "Not equal x");
    Assert.notEqual(affine[1], expected[1], "Not equal y");
  }
  function testSim_Mul_8() public {

    int256[4] memory k_l = [int256(112233445566778899), int256(0), int256(112233445566778899112233445566778899), int256(0)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8];
    
    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0x97cf778d84ceb33f3f4a931c58e226510a14d2b30a421a6a23d13b76e370fadd, 0x719219b6eb7b952d28be5950564addcf7c82f582901d38af32c5a088eb2fbfc4, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");
  }
  function testSim_Mul_9() public {
    
    int256[4] memory k_l = [int256(3126610171581712625568349792782341601976381592917186045901679), int256(1204381510338939288174307881319549068379512133475783491452928), int256(0), int256(0)];

    uint256[4] memory P_Q = [0x397a915943d5c8192c79fea8a4b6d45be41e0a9ae2722c1e192a009cb9f38ce3, 0x09fb51558a73827c2571280f89adb0fe5626497ef54061836d2c83bb101d88ac, 0x1f4dbca087a1972d04a07a779b7df1caa99e0f5db2aa21f3aecc4f9e10e85d08, 0xde491dbc6da808b7721cfe6ba322d366a63e12d0a789922c36a74c7260c88300];
    
    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0x3596f1f475c8999ffe35ccf7cebee7373ee40513ad467e3fc38600aa06d41bcf, 0x825a3eb4f09a55637391c950ba5e25c1ea658a15f234c14ebec79e5c68bd4133, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");
  }
  function testSim_Mul_10() public {
    
    int256[4] memory k_l = [int256(0), int256(0), int256(214823561579703732191260798632035497361172641107100392177584), int256(328478121366914896447265557982456186031632316080993096171520)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0x1f4dbca087a1972d04a07a779b7df1caa99e0f5db2aa21f3aecc4f9e10e85d08, 0x21b6e2439257f7488de301945cdd2c9959c1ed2f58766dd3c958b38c9f37792f];
    
    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0x1c2a90c4c30f60e878d1fe317acf4f2e059300e3deaa1c949628096ecaf993b2, 0x62bd40f3ca289a3ddbd8eddfa17074e15a770b8f5967f4de436104b44cc519e9, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");
  }
  function testSim_Mul_11() public {
    int256[4] memory k_l = [int256(3126610171581712625568349792782341601976381592917186045901679), int256(1204381510338939288174307881319549068379512133475783491452928), int256(214823561579703732191260798632035497361172641107100392177584), int256(328478121366914896447265557982456186031632316080993096171520)];

    uint256[4] memory P_Q = [0x397a915943d5c8192c79fea8a4b6d45be41e0a9ae2722c1e192a009cb9f38ce3, 0x09fb51558a73827c2571280f89adb0fe5626497ef54061836d2c83bb101d88ac, 0x1f4dbca087a1972d04a07a779b7df1caa99e0f5db2aa21f3aecc4f9e10e85d08, 0x21b6e2439257f7488de301945cdd2c9959c1ed2f58766dd3c958b38c9f37792f];

    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0x957f0c13905d357d9e1ebaf32742b410d423fcf2410229d4e8093f3360d07b2c, 0x9a0d14288d3906e052bdcf12c2a469da3e7449068b3e119300b792da964ed977, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");
  }
  function testSim_Mul_12() public {
    int256[4] memory k_l = [int256(3126610171581712625568349792782341601976381592917186045901679), int256(1204381510338939288174307881319549068379512133475783491452928), int256(0), int256(0)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0x397a915943d5c8192c79fea8a4b6d45be41e0a9ae2722c1e192a009cb9f38ce3, 0x09fb51558a73827c2571280f89adb0fe5626497ef54061836d2c83bb101d88ac];

    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0x47d3bf8910662b791e516fb6f626a4151c0be4efbf478f23a51153440408ea65, 0xc22e19a0b3ec85a41d371ce0fe0c5c5207313f8d981eec599cc645691c49b1d8, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");
  }
  function testSim_Mul_13() public {
    int256[4] memory k_l = [int256(3126610171581712625568349792782341601976381592917186045901679), int256(1204381510338939288174307881319549068379512133475783491452928), int256(214823561579703732191260798632035497361172641107100392177584), int256(328478121366914896447265557982456186031632316080993096171520)];

    uint256[4] memory P_Q = [0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8, 0x2c8c31fc9f990c6b55e3865a184a4ce50e09481f2eaeb3e60ec1cea13a6ae645, 0x64b95e4fdb6948c0386e189b006a29f686769b011704275e4459822dc3328085];

    uint256[3] memory kP_lQ = _sim_mul(k_l, P_Q, 0, pp);

    uint256[3] memory expected = [0xc71cd5625cd61d65bd9f6b84292eae013fc50ea99a9a090c730c3a4c24c32cc7, 0xebe10326af2accc2f3a4eb8658d90e572061aa766d04e31f102b26e7065c9f26, 1];

    uint256[2] memory affine;
    (affine[0], affine[1]) = toAffine(kP_lQ[0], kP_lQ[1], kP_lQ[2], pp);

    Assert.equal(affine[0], expected[0], "Not equal x");
    Assert.equal(affine[1], expected[1], "Not equal y");
  }

}

