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

// --> this is in natural byte order
// var BLOCK_100K_TRANSACTIONS = [
//   "6c01cec5275b19bfa26413513111066732b6f4163581c203cdf6cbdd2385219b",
//   "c308000b4e912907f53abea9d0517d30b634a827153b0f91e77ca34a480f440e",
//   "12ebcdd62faeb8be30f27a8ac457a23ba37f641f4fd25a1e6e2460f90e29e268",
//   "953f0da2eeb2cb0d6cd48c7ed9f216d5c4367091af6cd5d0ac5832da366e6d3d",
//   "beb540fb0ac38c95d78ba727a4c10ba2878696bdf52d177ca15eed99c9fef41d",
//   "4ba86e2dc9312012bc983d3b24bdb89b34d60013c7b95fd8ac8f4abda4f8591a",
//   "b65c6dd561d116a781e2fb90f4df8c2cd8e848f6da252f50723e9f0f4c2820a1",
//   "7c123bf23acddce83c2913daaa1550b7d57da32a8f98646ce2b8f336f3dfdfcc",
//   "43de34ee45c030f05450cee186cf7f658618b271c4a6b31e334655417cfec548",
//   "03c913821cf8ad218d6dc6ddf8c3c576f191e5644da839afe78522e749d0cb13",
//   "4f66cdf0990dc14e43e0029162848f4316c2ee43784415f0a18a0fc64893636c",
// ];
var BLOCK_100K_TRANSACTIONS = [
  "1f841d0e900e4b1fde938720e9a94fafb784f4ce14cd73a0b2af9801d4fceb1b",
  "ee3c9bf61031ef8ac165a884031364ca7b59737634a2d6e81bb3873068be5808",
  "402a1fd6c9d93b01955bbe801bd07234c6cef4c9fd0b5b0a9fcac6c6d3205289",
  "38fd1f00dab6788422b36f1443937ee1dcc3ac26634b15f57d4252a20cce5e0c",
  "3ecbeebc1ec4eec00c780656f0324eb8edb1a8db87ba2e587d0bb4844a66cae6",
  "82263db81a0f6fc9c6fbf76db9a1adf5abd1f8981d54e602f8cb238e89c25ceb",
  "88a22e555edd0ef30339721390995390326a120696e1e56fcd2929680fb025c4",
  "eadb0796ecf9ce39f78a983463e184cab3ebda3788c9bc4dc3129e9ae20302ae",
  "32ab2c5b22cf399b014cb1b262ae3bd09802f709c620072eb4ecf3b8b0b625f7",
  "825e3a55fbe6fd9dd44dfc0a4756cd69048a931a7ef756fa5f876f0fc370afef",
  "ac40542e4c6e25c83981f041c37ce5ba4dc88feecbbf47a2ac7f9d07ff7885f4",
];
var proofOfFirstTx = merkleNoRev.getProof(BLOCK_100K_TRANSACTIONS, 7);
var root = merkleNoRev.getMerkleRoot(BLOCK_100K_TRANSACTIONS);
console.log(root);

console.log(proofOfFirstTx);
console.log("hello");
