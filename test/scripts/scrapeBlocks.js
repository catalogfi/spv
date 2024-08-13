const { writeFileSync } = require("fs");
const { formatBlock } = require("./formatBlock");
const { join } = require("path");
const API_URL = "http://localhost:30000/blocks/";

(async () => {
    let start = 2000;
    let end = 4032;
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
        join(__dirname, "..", "fixtures", "difficultyEpoch_regtest.json"),
        JSON.stringify(blocks.reverse())
    );

    console.log(blocks.length);
})();
