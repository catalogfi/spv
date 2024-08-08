const formatBlock = (block) => {
    const version = Buffer.alloc(4);
    version.writeInt32LE(block.version, 0);

    const timestamp = Buffer.alloc(4);
    timestamp.writeUInt32LE(block.timestamp, 0);

    const nBits = Buffer.alloc(4);
    nBits.writeUint32LE(block.bits, 0);

    const nonce = Buffer.alloc(4);
    nonce.writeUInt32LE(block.nonce, 0);

    return {
        version: "0x" + version.toString("hex"),
        timestamp: "0x" + timestamp.toString("hex"),
        nBits: "0x" + nBits.toString("hex"),
        nonce: "0x" + nonce.toString("hex"),
        previousBlockHash:
            "0x" +
            Buffer.from(block.previousblockhash, "hex")
                .reverse()
                .toString("hex"),
        merkleRootHash:
            "0x" +
            Buffer.from(block.merkle_root, "hex").reverse().toString("hex"),
    };
};

module.exports = {
    formatBlock,
};
