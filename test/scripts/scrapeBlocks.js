const { writeFileSync } = require("fs");
const { formatBlock } = require("./formatBlock");
const { join } = require("path");
const API_URL = "https://mempool.space/testnet4/api/blocks/";

(async () => {
    let start = (38304 - 2016);
    let end = 38310;
    const blocks = [];
    while (end >= start) {
        const blockResponse = await fetch(API_URL + end).then((res) =>
            res.json()
        );
        blocks.push(
            ...blockResponse.map((block) => {
                return formatBlock(block);
            })
        );
        end -= blockResponse.length;
    }

    writeFileSync(
        join(__dirname, "..", "fixtures", "difficultyEpoch_testnet.json"),
        JSON.stringify(blocks.reverse())
    );
})();
