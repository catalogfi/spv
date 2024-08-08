// const txs = [
//     {
//         txHash: "5bc599d15bc83230bef230c71967f3c3ce875815c67e565b72c6ebdd66c09d91",
//         merkle: [
//             "44c2f479754420cec21bf944d3cf9a76ce71cb247d8dc8627ca8ac0c4819f281",
//             "97beb2063a9779f37dcf6dd02c7384422a5505889ab48de160aca9fe5e2a20e9",
//             "5e62deb4281fbf54b04e8d796bec37aea760cf146c9ddfdf96a7fce899328172",
//             "b9c3d6e18829ecec0750d3c4b7b129aa1798b4c5e78d54624384ce725849a554",
//             "5eab24ff5ad276a0e54ce0f8d675f3cda1945abcf62a0567f85dc6703a240cb0",
//             "a2251bee1285035d7793f85374e6328d9e32fe71e21fe648346290ee786d7835",
//             "1cc098215f0c3e91bc7de6037e2be394cf01c9f4416c9d4da65013ecbb1e1835",
//             "5aab16ef62abb9146f47d7c7e2285ebb67b9881764a9ecac8869f3e91c4f7666",
//             "0d007d13fb38235e19f9679f7c4281de4d49ed7ad27e07b526d9409313aec6ac",
//         ],
//         pos: 333,
//     },
//     {
//         txHash: "c50905d9ea64b227f940b0be2d806510da244880fee71996c95bb1e0799831b8",
//         merkle: [
//             "dd054951fa9dcbc134953e87304ec91ec9d37da8a186f5ebcc684994f5b2d6d1",
//             "5c2bf8b1d48ed529cdc652d6a585a2a107b8d5021b20e89b060e6b894f5837f9",
//             "5e62deb4281fbf54b04e8d796bec37aea760cf146c9ddfdf96a7fce899328172",
//             "b9c3d6e18829ecec0750d3c4b7b129aa1798b4c5e78d54624384ce725849a554",
//             "5eab24ff5ad276a0e54ce0f8d675f3cda1945abcf62a0567f85dc6703a240cb0",
//             "a2251bee1285035d7793f85374e6328d9e32fe71e21fe648346290ee786d7835",
//             "1cc098215f0c3e91bc7de6037e2be394cf01c9f4416c9d4da65013ecbb1e1835",
//             "5aab16ef62abb9146f47d7c7e2285ebb67b9881764a9ecac8869f3e91c4f7666",
//             "0d007d13fb38235e19f9679f7c4281de4d49ed7ad27e07b526d9409313aec6ac",
//         ],
//         pos: 334,
//     },
//     {
//         txHash: "dd054951fa9dcbc134953e87304ec91ec9d37da8a186f5ebcc684994f5b2d6d1",
//         merkle: [
//             "c50905d9ea64b227f940b0be2d806510da244880fee71996c95bb1e0799831b8",
//             "5c2bf8b1d48ed529cdc652d6a585a2a107b8d5021b20e89b060e6b894f5837f9",
//             "5e62deb4281fbf54b04e8d796bec37aea760cf146c9ddfdf96a7fce899328172",
//             "b9c3d6e18829ecec0750d3c4b7b129aa1798b4c5e78d54624384ce725849a554",
//             "5eab24ff5ad276a0e54ce0f8d675f3cda1945abcf62a0567f85dc6703a240cb0",
//             "a2251bee1285035d7793f85374e6328d9e32fe71e21fe648346290ee786d7835",
//             "1cc098215f0c3e91bc7de6037e2be394cf01c9f4416c9d4da65013ecbb1e1835",
//             "5aab16ef62abb9146f47d7c7e2285ebb67b9881764a9ecac8869f3e91c4f7666",
//             "0d007d13fb38235e19f9679f7c4281de4d49ed7ad27e07b526d9409313aec6ac",
//         ],
//         pos: 335,
//     },
//     {
//         txHash: "444995ed8e7304d66449c3e7943c5a096cbed79ee7f422bbabfb843cb0405afc",
//         merkle: [
//             "669a572437a6e896714f822b4193827ff77b270829ea56b39465a737cf20f3fe",
//             "97f0f1204150726f365c5cb2ca334824314c593bc375ec55d0f177313c43962d",
//             "79113918df8289b1eb8367eb419d7146e3c440bfb2b6d5a749d2e99bb8aa2753",
//             "d04c2eac4efa673db38941eed5fa97f26cb7cd819899f574e49ab9ef8f7e9e1b",
//             "0ee7c9cd7a7ecaae9637e5960b7a616bc5c7861ae06fe517ab1528e4567fc96b",
//             "a2251bee1285035d7793f85374e6328d9e32fe71e21fe648346290ee786d7835",
//             "1cc098215f0c3e91bc7de6037e2be394cf01c9f4416c9d4da65013ecbb1e1835",
//             "5aab16ef62abb9146f47d7c7e2285ebb67b9881764a9ecac8869f3e91c4f7666",
//             "0d007d13fb38235e19f9679f7c4281de4d49ed7ad27e07b526d9409313aec6ac",
//         ],
//         pos: 336,
//     },
//     {
//         txHash: "669a572437a6e896714f822b4193827ff77b270829ea56b39465a737cf20f3fe",
//         merkle: [
//             "444995ed8e7304d66449c3e7943c5a096cbed79ee7f422bbabfb843cb0405afc",
//             "97f0f1204150726f365c5cb2ca334824314c593bc375ec55d0f177313c43962d",
//             "79113918df8289b1eb8367eb419d7146e3c440bfb2b6d5a749d2e99bb8aa2753",
//             "d04c2eac4efa673db38941eed5fa97f26cb7cd819899f574e49ab9ef8f7e9e1b",
//             "0ee7c9cd7a7ecaae9637e5960b7a616bc5c7861ae06fe517ab1528e4567fc96b",
//             "a2251bee1285035d7793f85374e6328d9e32fe71e21fe648346290ee786d7835",
//             "1cc098215f0c3e91bc7de6037e2be394cf01c9f4416c9d4da65013ecbb1e1835",
//             "5aab16ef62abb9146f47d7c7e2285ebb67b9881764a9ecac8869f3e91c4f7666",
//             "0d007d13fb38235e19f9679f7c4281de4d49ed7ad27e07b526d9409313aec6ac",
//         ],
//         pos: 337,
//     },
//     {
//         txHash: "06d734718baff2e62520ca4f789ae28e4460def68e7672d5ff0a3df39d7f0f91",
//         merkle: [
//             "1805d493f560881f9d51d942a3126db5360539ed968757ebe787286e8aae06bf",
//             "814f714c2a6b80eda23daab303f9863acef1d27d736daa57cc5c66896cc022b6",
//             "0c81e1ef856961ab08d77df79b761f3062c540229128693a8e6073dea1d1d99f",
//             "b9c3d6e18829ecec0750d3c4b7b129aa1798b4c5e78d54624384ce725849a554",
//             "5eab24ff5ad276a0e54ce0f8d675f3cda1945abcf62a0567f85dc6703a240cb0",
//             "a2251bee1285035d7793f85374e6328d9e32fe71e21fe648346290ee786d7835",
//             "1cc098215f0c3e91bc7de6037e2be394cf01c9f4416c9d4da65013ecbb1e1835",
//             "5aab16ef62abb9146f47d7c7e2285ebb67b9881764a9ecac8869f3e91c4f7666",
//             "0d007d13fb38235e19f9679f7c4281de4d49ed7ad27e07b526d9409313aec6ac",
//         ],
//         pos: 328,
//     },
//     {
//         txHash: "1805d493f560881f9d51d942a3126db5360539ed968757ebe787286e8aae06bf",
//         merkle: [
//             "06d734718baff2e62520ca4f789ae28e4460def68e7672d5ff0a3df39d7f0f91",
//             "814f714c2a6b80eda23daab303f9863acef1d27d736daa57cc5c66896cc022b6",
//             "0c81e1ef856961ab08d77df79b761f3062c540229128693a8e6073dea1d1d99f",
//             "b9c3d6e18829ecec0750d3c4b7b129aa1798b4c5e78d54624384ce725849a554",
//             "5eab24ff5ad276a0e54ce0f8d675f3cda1945abcf62a0567f85dc6703a240cb0",
//             "a2251bee1285035d7793f85374e6328d9e32fe71e21fe648346290ee786d7835",
//             "1cc098215f0c3e91bc7de6037e2be394cf01c9f4416c9d4da65013ecbb1e1835",
//             "5aab16ef62abb9146f47d7c7e2285ebb67b9881764a9ecac8869f3e91c4f7666",
//             "0d007d13fb38235e19f9679f7c4281de4d49ed7ad27e07b526d9409313aec6ac",
//         ],
//         pos: 329,
//     },
//     {
//         txHash: "a4c4611dd9fa2d1fbb7e34c4447913b10ec65f4d16dcf169f250e1592e709d31",
//         merkle: [
//             "63050fa0e4b9f96b18d68dca34db39ddf3fb42ab1e119876a8452e61140fac73",
//             "f3f0f229c74867ca7d43fc20743515e5597f9a11a081649b689770952d1f4736",
//             "0c81e1ef856961ab08d77df79b761f3062c540229128693a8e6073dea1d1d99f",
//             "b9c3d6e18829ecec0750d3c4b7b129aa1798b4c5e78d54624384ce725849a554",
//             "5eab24ff5ad276a0e54ce0f8d675f3cda1945abcf62a0567f85dc6703a240cb0",
//             "a2251bee1285035d7793f85374e6328d9e32fe71e21fe648346290ee786d7835",
//             "1cc098215f0c3e91bc7de6037e2be394cf01c9f4416c9d4da65013ecbb1e1835",
//             "5aab16ef62abb9146f47d7c7e2285ebb67b9881764a9ecac8869f3e91c4f7666",
//             "0d007d13fb38235e19f9679f7c4281de4d49ed7ad27e07b526d9409313aec6ac",
//         ],
//         pos: 330,
//     },
//     {
//         txHash: "63050fa0e4b9f96b18d68dca34db39ddf3fb42ab1e119876a8452e61140fac73",
//         merkle: [
//             "a4c4611dd9fa2d1fbb7e34c4447913b10ec65f4d16dcf169f250e1592e709d31",
//             "f3f0f229c74867ca7d43fc20743515e5597f9a11a081649b689770952d1f4736",
//             "0c81e1ef856961ab08d77df79b761f3062c540229128693a8e6073dea1d1d99f",
//             "b9c3d6e18829ecec0750d3c4b7b129aa1798b4c5e78d54624384ce725849a554",
//             "5eab24ff5ad276a0e54ce0f8d675f3cda1945abcf62a0567f85dc6703a240cb0",
//             "a2251bee1285035d7793f85374e6328d9e32fe71e21fe648346290ee786d7835",
//             "1cc098215f0c3e91bc7de6037e2be394cf01c9f4416c9d4da65013ecbb1e1835",
//             "5aab16ef62abb9146f47d7c7e2285ebb67b9881764a9ecac8869f3e91c4f7666",
//             "0d007d13fb38235e19f9679f7c4281de4d49ed7ad27e07b526d9409313aec6ac",
//         ],
//         pos: 331,
//     },
//     {
//         txHash: "44c2f479754420cec21bf944d3cf9a76ce71cb247d8dc8627ca8ac0c4819f281",
//         merkle: [
//             "5bc599d15bc83230bef230c71967f3c3ce875815c67e565b72c6ebdd66c09d91",
//             "97beb2063a9779f37dcf6dd02c7384422a5505889ab48de160aca9fe5e2a20e9",
//             "5e62deb4281fbf54b04e8d796bec37aea760cf146c9ddfdf96a7fce899328172",
//             "b9c3d6e18829ecec0750d3c4b7b129aa1798b4c5e78d54624384ce725849a554",
//             "5eab24ff5ad276a0e54ce0f8d675f3cda1945abcf62a0567f85dc6703a240cb0",
//             "a2251bee1285035d7793f85374e6328d9e32fe71e21fe648346290ee786d7835",
//             "1cc098215f0c3e91bc7de6037e2be394cf01c9f4416c9d4da65013ecbb1e1835",
//             "5aab16ef62abb9146f47d7c7e2285ebb67b9881764a9ecac8869f3e91c4f7666",
//             "0d007d13fb38235e19f9679f7c4281de4d49ed7ad27e07b526d9409313aec6ac",
//         ],
//         pos: 332,
//     },
// ];

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
