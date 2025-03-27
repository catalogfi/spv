const btcProof = require("bitcoin-proof");
const merkle = require("./merkle");

var BLOCK_100K_TRANSACTIONS = [
  "0x6c01cec5275b19bfa26413513111066732b6f4163581c203cdf6cbdd2385219b",
  "0xc308000b4e912907f53abea9d0517d30b634a827153b0f91e77ca34a480f440e",
  "0x12ebcdd62faeb8be30f27a8ac457a23ba37f641f4fd25a1e6e2460f90e29e268",
  "0x953f0da2eeb2cb0d6cd48c7ed9f216d5c4367091af6cd5d0ac5832da366e6d3d",
  "0xbeb540fb0ac38c95d78ba727a4c10ba2878696bdf52d177ca15eed99c9fef41d",
  "0x4ba86e2dc9312012bc983d3b24bdb89b34d60013c7b95fd8ac8f4abda4f8591a",
  "0xb65c6dd561d116a781e2fb90f4df8c2cd8e848f6da252f50723e9f0f4c2820a1",
  "0x7c123bf23acddce83c2913daaa1550b7d57da32a8f98646ce2b8f336f3dfdfcc",
  "0x43de34ee45c030f05450cee186cf7f658618b271c4a6b31e334655417cfec548",
  "0x03c913821cf8ad218d6dc6ddf8c3c576f191e5644da839afe78522e749d0cb13",
  "0x4f66cdf0990dc14e43e0029162848f4316c2ee43784415f0a18a0fc64893636c",
];

var proofOfFirstTx = merkle.getProof(BLOCK_100K_TRANSACTIONS,0);

console.log(proofOfFirstTx);
console.log("hello");
