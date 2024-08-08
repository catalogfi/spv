// const block = {
//     id: "000000000000000000023bfd7af8a3158e100f703464ce41e4f5d24eb12706c5",
//     height: 855730,
//     version: 674537472,
//     timestamp: 1723005758,
//     tx_count: 369,
//     size: 1055830,
//     weight: 3993538,
//     merkle_root:
//         "f3b7768a99f2b568a9cd5d88ec93aba63c2bb36c01191e82389f68d084fa7719",
//     previousblockhash:
//         "00000000000000000001d18d2605c0667e19c84aa9842accd6ee6960dce3da18",
//     mediantime: 1722999520,
//     nonce: 3129127240,
//     bits: 386079422,
//     difficulty: 90666502495565.78,
// };

const block = {
    id: "000000000000000000026b90d09b5e4fba615eadfc4ce2a19f6a68c9c18d4a2e",
    height: 842688,
    version: 671080448,
    timestamp: 1715252414,
    tx_count: 5579,
    size: 1596177,
    weight: 3993336,
    merkle_root:
        "d97087f7086697e78f390fdfa639392ab69fd740e5609f635931bc032072b162",
    previousblockhash:
        "000000000000000000021342b77cc83903ed85341a53b9ec571fb7b0a503124c",
    mediantime: 1715250633,
    nonce: 3431100067,
    bits: 386097818,
    difficulty: 83148355189239.77,
};

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

// console.log(formatBlock(block));
