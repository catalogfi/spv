const { writeFileSync } = require("fs");
const { formatBlock } = require("./formatBlock");
const { join } = require("path");
const API_URL = "https://mempool.space/api/v1/blocks/";

(async () => {
    let start = 840672;
    let end = 842700;
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
        join(__dirname, "..", "fixtures", "difficultyEpoch.json"),
        JSON.stringify(blocks.reverse())
    );
})();
