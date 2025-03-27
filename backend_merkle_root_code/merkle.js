const { createHash } = require("crypto");

/**
 * Double SHA-256 hash function
 * @param {Buffer} buf1
 * @param {Buffer} [buf2]
 * @return {Buffer}
 */
function sha256x2(buf1, buf2 = Buffer.alloc(0)) {
  return createHash("sha256")
    .update(createHash("sha256").update(buf1).update(buf2).digest())
    .digest();
}

/**
 * Reverse a buffer (Bitcoin uses little-endian)
 * @param {Buffer} buf
 * @return {Buffer}
 */
function reverse(buf) {
  return Buffer.from(buf).reverse();
}

/**
 * Check if two buffers are equal
 * @param {Buffer} buf1
 * @param {Buffer} buf2
 * @return {boolean}
 */
function isEqual(buf1, buf2) {
  return buf1.equals(buf2);
}

/**
 * @typedef {Object} ProofObject
 * @property {string} txId
 * @property {number} txIndex
 * @property {string[]} sibling
 */

/**
 * Generate a Merkle proof for a given transaction
 * @param {string[]} txIds - List of transaction hashes (hex strings)
 * @param {number} txIndex - Index of the transaction to prove
 * @return {ProofObject}
 */
function getProof(txIds, txIndex) {
  const proof = {
    txId: txIds[txIndex],
    txIndex,
    sibling: [],
  };

  let tree = txIds.map((tx) =>
    reverse(Buffer.from(tx.replace(/^0x/, ""), "hex"))
  );
  let target = tree[txIndex];

  while (tree.length > 1) {
    if (tree.length % 2 === 1) {
      // Duplicate the last node if the number of elements is odd
      tree.push(tree[tree.length - 1]);
    }

    const newTree = [];
    for (let i = 0; i < tree.length; i += 2) {
      const hash1 = tree[i];
      const hash2 = tree[i + 1];

      newTree.push(sha256x2(hash1, hash2));

      if (isEqual(target, hash1)) {
        proof.sibling.push(reverse(hash2).toString("hex"));
        target = newTree[newTree.length - 1];
      } else if (isEqual(target, hash2)) {
        proof.sibling.push(reverse(hash1).toString("hex"));
        target = newTree[newTree.length - 1];
      }
    }

    tree = newTree;
  }

  return proof;
}

/**
 * Verify a Merkle proof and reconstruct the root
 * @param {ProofObject} proofObj
 * @return {string} - The computed Merkle root
 */
function getTxMerkle(proofObj) {
  let target = reverse(Buffer.from(proofObj.txId.replace(/^0x/, ""), "hex"));
  let txIndex = proofObj.txIndex;

  for (const siblingHash of proofObj.sibling) {
    const sibling = reverse(Buffer.from(siblingHash, "hex"));

    if (txIndex % 2 === 1) {
      target = sha256x2(sibling, target);
    } else {
      target = sha256x2(target, sibling);
    }
    txIndex = Math.floor(txIndex / 2);
  }

  return reverse(target).toString("hex");
}

/**
 * Compute the Merkle root from a list of transaction IDs
 * @param {string[]} txIds - List of transaction hashes (hex strings)
 * @return {string} - The computed Merkle root
 */
function getMerkleRoot(txIds) {
  let tree = txIds.map((tx) =>
    reverse(Buffer.from(tx.replace(/^0x/, ""), "hex"))
  );

  while (tree.length > 1) {
    if (tree.length % 2 === 1) {
      tree.push(tree[tree.length - 1]);
    }

    const newTree = [];
    for (let i = 0; i < tree.length; i += 2) {
      newTree.push(sha256x2(tree[i], tree[i + 1]));
    }
    tree = newTree;
  }

  return reverse(tree[0]).toString("hex");
}

// Export functions
module.exports = {
  getProof,
  getTxMerkle,
  getMerkleRoot,
};
