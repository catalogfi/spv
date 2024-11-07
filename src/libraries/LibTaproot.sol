// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

import {LibEllipticCurve} from "./LibEllipticCurve.sol";
import {LibBitcoin} from "./LibBitcoin.sol";

library LibTaproot {
    uint256 public constant GX =
        0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY =
        0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 public constant OO =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    bytes32 public constant TAP_LEAF_HASH =
        0xaeea8fdc4208983105734b58081d1e2638d35f1cb54008d4d357ca03be78e9ee;
    bytes32 public constant TAP_BRANCH_HASH =
        0x1941a1f2e56eb95fa2a9f194be5c01f7216f33ed82b091463490d05bf516a015;
    bytes32 public constant TAP_TWEAK_HASH =
        0xe80fe1639c9ca050e3af1b39c143c63e429cbceb15d940fbb5c5a1f4af57c5e9;

    uint256 public constant TAPROOT_NUMS_X =
        36444060476547731421425013472121489344383018981262552973668657287772036414144;
    uint256 public constant TAPROOT_NUMS_Y =
        22537504475708154238330251540244790414456712057027634449505794721772594235652;

    bytes1 public constant LEAF_VERSION = 0xC0;
    bytes32 public constant BIP340_CHALLENGE_HASH =
        0x7BB52D7A9FEF58323EB1BF7A407DB382D2F3F2D81BB1224F49FE518F6D48D37C;

    function pubkeyToAddress(
        bytes memory pubkey
    ) internal pure returns (address) {
        bytes32 hash = keccak256(pubkey);
        return address(uint160(uint256(hash)));
    }

    function verifySchnorr(
        uint8 parity,
        uint256 PX,
        bytes32[] memory signature,
        bytes memory message
    ) external pure returns (bool) {
        require(parity < 2, "Parity should be 0 or 1");
        require(
            signature.length == 2,
            "Signature should be an array of length 2, [R, s]"
        );

        uint256 RX = uint256(signature[0]);
        uint256 s = uint256(signature[1]);

        uint256 RY = LibEllipticCurve.deriveY(0x02, RX, AA, BB, PP);

        bytes32 messageChallenge = sha256(
            bytes.concat(
                BIP340_CHALLENGE_HASH,
                BIP340_CHALLENGE_HASH,
                bytes32(RX),
                bytes32(PX),
                message
            )
        );

        bytes32 sP_x = bytes32(OO - mulmod(s, PX, OO));
        bytes32 eP_x = bytes32(OO - mulmod(uint256(messageChallenge), PX, OO));

        address computedAddress = ecrecover(
            sP_x,
            parity + 27,
            bytes32(PX),
            eP_x
        );

        require(computedAddress != address(0), "Invalid signature");

        return pubkeyToAddress(abi.encodePacked(RX, RY)) == computedAddress;
    }

    function tweak(
        uint256 PX,
        uint256 PY,
        uint256 tweakValue
    ) internal pure returns (uint256, uint256) {
        (uint256 TX, uint256 TY) = LibEllipticCurve.ecMul(
            tweakValue,
            GX,
            GY,
            AA,
            PP
        );
        (uint256 QX, uint256 QY) = LibEllipticCurve.ecAdd(
            PX,
            PY,
            TX,
            TY,
            AA,
            PP
        );

        return (QX, QY);
    }

    function taggedHashLeaf(bytes memory data) internal pure returns (bytes32) {
        return precomputedTaggedHash(TAP_LEAF_HASH, data);
    }

    function taggedHashBranch(
        bytes memory data
    ) internal pure returns (bytes32) {
        return precomputedTaggedHash(TAP_BRANCH_HASH, data);
    }

    function taggedHashTweak(
        bytes memory data
    ) internal pure returns (bytes32) {
        return precomputedTaggedHash(TAP_TWEAK_HASH, data);
    }

    function precomputedTaggedHash(
        bytes32 tagHash,
        bytes memory data
    ) internal pure returns (bytes32) {
        return sha256(bytes.concat(tagHash, tagHash, data));
    }

    function taggedHash(
        bytes memory tag,
        bytes memory data
    ) internal pure returns (bytes32) {
        bytes32 tagHash = sha256(tag);

        return precomputedTaggedHash(tagHash, data);
    }

    function serializeScript(
        bytes calldata script
    ) internal pure returns (bytes memory) {
        require(script.length < 0xffffffff, "Taproot: Script too long");
        return
            bytes.concat(
                LEAF_VERSION,
                LibBitcoin.encodeVarint(uint64(script.length)),
                script
            );
    }

    function computeMastRootFromMerkleProof(
        bytes calldata script,
        bytes32[] calldata merkleProof
    ) public pure returns (bytes32) {
        bytes32 hash = taggedHashLeaf(serializeScript(script));
        for (uint256 i = 0; i < merkleProof.length; i++) {
            bytes memory data;
            if (hash < merkleProof[i]) {
                data = bytes.concat(hash, merkleProof[i]);
            } else {
                data = bytes.concat(merkleProof[i], hash);
            }
            hash = taggedHashBranch(data);
        }

        return hash;
    }

    // function verifyTaprootScriptPubKeyWithNumsTweak(bytes32 spk, bytes calldata script, bytes32[] calldata merkleProof, uint256 tweakValue) public pure returns (bool) {
    //     (uint tGX, uint tGY) = LibEllipticCurve.ecMul(tweakValue, GX, GY, AA, PP);

    //     return verifyTaprootScriptPubKey(spk, script, merkleProof, tGX, tGY);
    // }

    // function verifyTaprootScriptPubKeyWithNums(bytes32 spk, bytes calldata script, bytes32[] calldata merkleProof) public pure returns (bool) {
    //     return verifyTaprootScriptPubKey(spk, script, merkleProof, TAPROOT_NUMS_X);
    // }

    function verifyTaprootScriptPubKey(
        bytes32 spk,
        bytes calldata script,
        bytes32[] calldata merkleProof,
        uint256 PX
    ) public pure returns (bool) {
        bytes32 mastRoot = computeMastRootFromMerkleProof(script, merkleProof);
        uint256 tweakValue = uint256(
            taggedHashTweak(bytes.concat(abi.encodePacked(PX), mastRoot))
        );

        require(
            tweakValue < OO,
            "Taproot: tweak should be within the curve order"
        );

        uint256 PY = LibEllipticCurve.deriveY(0x02, PX, AA, BB, PP);
        (uint256 QX, ) = tweak(PX, PY, tweakValue);

        //check for parity as well
        return uint256(spk) == QX;
    }

    function getTaprootScriptPubKey(
        bytes[] calldata scripts,
        uint256 PX
    ) public pure returns (bytes32 spk) {
        uint256 PY = LibEllipticCurve.deriveY(0x02, PX, AA, BB, PP);

        bytes32[] memory leafHashes = new bytes32[](scripts.length);
        for (uint256 i = 0; i < scripts.length; i++) {
            leafHashes[i] = taggedHashLeaf(serializeScript(scripts[i]));
        }

        bytes32 mastRoot = buildMerkleRoot(leafHashes);

        uint256 tweakValue = uint256(
            taggedHashTweak(bytes.concat(abi.encodePacked(PX), mastRoot))
        );

        require(
            tweakValue < OO,
            "Taproot: tweak should be within the curve order"
        );

        (uint256 QX, ) = tweak(PX, PY, tweakValue);

        return bytes32(QX);
    }

    /**
     * @dev Builds a Merkle root from an array of leaf hashes
     * @return bytes32 The Merkle root
     */
    function buildMerkleRoot(
        bytes32[] memory leafHashes
    ) private pure returns (bytes32) {
        if (leafHashes.length == 0) {
            return bytes32(0);
        }

        if (leafHashes.length == 1) {
            return leafHashes[0];
        }

        uint256 numNodes = leafHashes.length;
        uint256 level = 0;

        while (numNodes > 1) {
            numNodes = (numNodes + 1) / 2;
            level++;
        }

        bytes32[] memory currentLevel = new bytes32[](leafHashes.length);
        for (uint256 i = 0; i < leafHashes.length; i++) {
            currentLevel[i] = leafHashes[i];
        }

        while (level > 0) {
            uint256 numPairs = (currentLevel.length + 1) / 2;
            bytes32[] memory nextLevel = new bytes32[](numPairs);

            for (uint256 i = 0; i < numPairs; i++) {
                uint256 j = i * 2;
                if (j + 1 >= currentLevel.length) {
                    nextLevel[i] = currentLevel[j];
                } else {
                    bytes32 left = currentLevel[j];
                    bytes32 right = currentLevel[j + 1];

                    bytes memory data;
                    if (uint256(left) < uint256(right)) {
                        data = bytes.concat(left, right);
                    } else {
                        data = bytes.concat(right, left);
                    }
                    nextLevel[i] = taggedHashBranch(data);
                }
            }

            currentLevel = nextLevel;
            level--;
        }

        return currentLevel[0];
    }
}
