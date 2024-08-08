const crypto = require("crypto");

const hash = (buffer) => {
    return crypto.createHash("sha256").update(buffer).digest();
};

console.log(
    hash(
        hash(
            Buffer.from(
                "0000000000000000000000000000000000000000000000000000000000000000",
                "hex"
            )
        )
    ).toString("hex")
);
