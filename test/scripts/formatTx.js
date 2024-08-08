const txs = [
    {
        block_height: 840675,
        merkle: [
            "06efea2158e68b517c2cfdfb1f98139a56235deecb459869cb1d3d9e2f99621a",
            "f5e68a0dc7d5ddb655097fcbd9a526ad4021114503ed420a96af7f74d652760c",
            "65f0ebda06c62b5dc05a7b765ec07f0e28f1f62ac7d050f3c2eed6365b8bbac7",
            "c4b1fccbe9916c613df97507047507e6926fc6bffa567665674f30518549b72b",
            "9fd656bc0f79a492d8a76094c919474f13f6bb561a4525eba9f5c8eac0a3c8aa",
            "ed6fb414a527f95cdcb21999f3d30067f20ba7eb2f00a6eda6c71a725e1e07da",
            "dab4520cde70b2f5ea9c89b9008fb76286190a17192dcbfd3c0dcbbeabaff450",
            "827394f0bc01cfae020fc0ee854e276e4f62ac6ead9136f58e25bbd480fcb575",
            "aba3714e8f2595b041b1994794d5b61b95fe6b23c89092e003a4c88a3dd97c25",
            "4ccf80aa55e68536678325b54baf9b726d51f7ef6f9ef9dfd0220af729663c8a",
            "b4b34a0e78a6c629f3b23db162c2237010beac4322b62c0f395ad2b75d2e375f",
            "7a3cde7abc86525feb18c5973be98bdd054f42414a4ef4419c4c2453a721375a",
        ],
        pos: 636,
    },
];

const newTxs = [];
for (const tx of txs) {
    newTxs.push({
        txHash: "0x" + tx.txHash,
        merkle: tx.merkle.map(
            (x) => "0x" + Buffer.from(x, "hex").reverse().toString("hex")
        ),
        pos: tx.pos,
    });
}

console.log(newTxs);
