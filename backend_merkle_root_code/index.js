const btcProof = require("bitcoin-proof");
const merkle = require("./merkle");
const merkleNoRev = require("./merkle_root_no_reversal");

// reverse 
// var BLOCK_100K_TRANSACTIONS = [
//   "9b218523ddcbf6cd03c2813516f4b63267061131511364a2bf195b27c5ce016c",
//   "0e440f484aa37ce7910f3b1527a834b6307d51d0a9be3af50729914e0b0008c3",
//   "68e2290ef960246e1e5ad24f1f647fa33ba257c48a7af230beb8ae2fd6cdeb12",
//   "3d6d6e36da3258acd0d56caf917036c4d516f2d97e8cd46c0dcbb2eea20d3f95",
//   "1df4fec999ed5ea17c172df5bd968687a20bc1a427a78bd7958cc30afb40b5be",
//   "1a59f8a4bd4a8facd85fb9c71300d6349bb8bd243b3d98bc122031c92d6ea84b",
//   "a120284c0f9f3e72502f25daf648e8d82c8cdff490fbe281a716d161d56d5cb6",
//   "ccdfdff336f3b8e26c64988f2aa37dd5b75015aada13293ce8dccd3af23b127c",
//   "48c5fe7c415546331eb3a6c471b21886657fcf86e1ce5054f030c045ee34de43",
//   "13cbd049e72285e7af39a84d64e591f176c5c3f8ddc66d8d21adf81c8213c903",
//   "6c639348c60f8aa1f015447843eec216438f84629102e0434ec10d99f0cd664f",
// ];
var BLOCK_100K_TRANSACTIONS = [
  "6c01cec5275b19bfa26413513111066732b6f4163581c203cdf6cbdd2385219b",
  "c308000b4e912907f53abea9d0517d30b634a827153b0f91e77ca34a480f440e",
  "12ebcdd62faeb8be30f27a8ac457a23ba37f641f4fd25a1e6e2460f90e29e268",
  "953f0da2eeb2cb0d6cd48c7ed9f216d5c4367091af6cd5d0ac5832da366e6d3d",
  "beb540fb0ac38c95d78ba727a4c10ba2878696bdf52d177ca15eed99c9fef41d",
  "4ba86e2dc9312012bc983d3b24bdb89b34d60013c7b95fd8ac8f4abda4f8591a",
  "b65c6dd561d116a781e2fb90f4df8c2cd8e848f6da252f50723e9f0f4c2820a1",
  "7c123bf23acddce83c2913daaa1550b7d57da32a8f98646ce2b8f336f3dfdfcc",
  "43de34ee45c030f05450cee186cf7f658618b271c4a6b31e334655417cfec548",
  "03c913821cf8ad218d6dc6ddf8c3c576f191e5644da839afe78522e749d0cb13",
  "4f66cdf0990dc14e43e0029162848f4316c2ee43784415f0a18a0fc64893636c",
];

var proofOfFirstTx = merkleNoRev.getProof(BLOCK_100K_TRANSACTIONS, 0);
var root = merkleNoRev.getMerkleRoot(BLOCK_100K_TRANSACTIONS);
console.log(root);

console.log(proofOfFirstTx);
console.log("hello");
