// SPDX-License-Identifier: MIT
library BabylonScriptUtils {
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct BabylonScriptPaths {
        bytes timeLockPathScript;
        bytes unbondingPathScript;
        bytes slashingPathScript;
    }

    struct ScriptParams {
        BabylonScriptUtils.PublicKey stakerKey;
        BabylonScriptUtils.PublicKey[] fpKeys;
        BabylonScriptUtils.PublicKey[] covenantKeys;
        uint32 covenantQuorum;
        uint16 lockTime;
    }

    error StakerKeyIsNil();
    error DuplicateKeysFound();
    error ScriptBuildingError();
    error NoKeysProvided();
    error InvalidThreshold();
    error InsufficientKeys();
    error InvalidPublicKey();

    // Constants for script operations (mimicking Bitcoin script ops)
    uint8 constant OP_CHECKSIG = 0xac;
    uint8 constant OP_CHECKSIGVERIFY = 0xad;
    uint8 constant OP_CHECKSIGADD = 0xba;
    uint8 constant OP_NUMEQUAL = 0x9c;
    uint8 constant OP_NUMEQUALVERIFY = 0x9d;
    uint8 constant OP_CHECKSEQUENCEVERIFY = 0xb2;

    /**
     * @dev Serializes a public key into bytes (similar to schnorr.SerializePubKey)
     */
    function serializePublicKey(
        PublicKey memory key
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(key.x, key.y);
    }

    /**
     * @dev Sorts public keys in lexicographical order
     */
    function sortKeys(
        PublicKey[] memory keys
    ) internal pure returns (PublicKey[] memory) {
        PublicKey[] memory sortedKeys = new PublicKey[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            sortedKeys[i] = keys[i];
        }

        // Bubble sort implementation (can be optimized for production)
        for (uint256 i = 0; i < sortedKeys.length - 1; i++) {
            for (uint256 j = 0; j < sortedKeys.length - i - 1; j++) {
                bytes memory keyJ = serializePublicKey(sortedKeys[j]);
                bytes memory keyJPlus1 = serializePublicKey(sortedKeys[j + 1]);

                if (compare(keyJ, keyJPlus1) > 0) {
                    PublicKey memory temp = sortedKeys[j];
                    sortedKeys[j] = sortedKeys[j + 1];
                    sortedKeys[j + 1] = temp;
                }
            }
        }

        return sortedKeys;
    }

    function compare(
        bytes memory a,
        bytes memory b
    ) internal pure returns (int8) {
        uint256 minLength = a.length < b.length ? a.length : b.length;

        for (uint256 i = 0; i < minLength; i++) {
            if (a[i] < b[i]) return -1;
            if (a[i] > b[i]) return 1;
        }

        if (a.length < b.length) return -1;
        if (a.length > b.length) return 1;
        return 0;
    }

    function buildMultiSigScript(
        PublicKey[] memory keys,
        uint32 threshold,
        bool withVerify
    ) internal pure returns (bytes memory) {
        if (keys.length == 0) revert NoKeysProvided();
        if (threshold > keys.length) revert InvalidThreshold();
        if (keys.length == 1) {
            return buildSingleKeySigScript(keys[0], withVerify);
        }
        if (keys.length < 2) revert InsufficientKeys();

        PublicKey[] memory sortedKeys = sortKeys(keys);
        return assembleMultiSigScript(sortedKeys, threshold, withVerify);
    }

    function assembleMultiSigScript(
        PublicKey[] memory pubkeys,
        uint32 threshold,
        bool withVerify
    ) internal pure returns (bytes memory) {
        bytes memory script;

        for (uint256 i = 0; i < pubkeys.length; i++) {
            script = abi.encodePacked(
                script,
                serializePublicKey(pubkeys[i]),
                i == 0 ? OP_CHECKSIG : OP_CHECKSIGADD
            );
        }

        return
            abi.encodePacked(
                script,
                uint256(threshold),
                withVerify ? OP_NUMEQUALVERIFY : OP_NUMEQUAL
            );
    }

    function buildTimeLockScript(
        PublicKey memory pubKey,
        uint16 lockTime
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                serializePublicKey(pubKey),
                OP_CHECKSIGVERIFY,
                uint256(lockTime),
                OP_CHECKSEQUENCEVERIFY
            );
    }

    function buildSingleKeySigScript(
        PublicKey memory pubKey,
        bool withVerify
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                serializePublicKey(pubKey),
                withVerify ? OP_CHECKSIGVERIFY : OP_CHECKSIG
            );
    }

    /**
     * @dev Builds all Babylon script paths using the provided parameters
     * @param params Script parameters including keys and timing values
     * @return BabylonScriptPaths containing all constructed scripts
     */
    function buildBabylonScriptPaths(
        ScriptParams memory params
    ) public pure returns (BabylonScriptPaths memory) {
        bytes memory timeLockPathScript = BabylonScriptUtils
            .buildTimeLockScript(params.stakerKey, params.lockTime);

        bytes memory covenantMultisigScript = BabylonScriptUtils
            .buildMultiSigScript(
                params.covenantKeys,
                params.covenantQuorum,
                false
            );

        bytes memory stakerSigScript = BabylonScriptUtils
            .buildSingleKeySigScript(params.stakerKey, true);

        bytes memory fpMultisigScript = BabylonScriptUtils.buildMultiSigScript(
            params.fpKeys,
            1,
            true
        );

        // Aggregate scripts
        bytes memory unbondingPathScript = _aggregateScripts(
            stakerSigScript,
            covenantMultisigScript
        );

        bytes memory slashingPathScript = _aggregateScripts(
            stakerSigScript,
            fpMultisigScript,
            covenantMultisigScript
        );

        return
            BabylonScriptPaths({
                timeLockPathScript: timeLockPathScript,
                unbondingPathScript: unbondingPathScript,
                slashingPathScript: slashingPathScript
            });
    }

    /**
     * @dev Aggregates multiple scripts into a single script
     */
    function _aggregateScripts(
        bytes memory script1,
        bytes memory script2
    ) private pure returns (bytes memory) {
        return bytes.concat(script1, script2);
    }

    /**
     * @dev Aggregates three scripts into a single script
     */
    function _aggregateScripts(
        bytes memory script1,
        bytes memory script2,
        bytes memory script3
    ) private pure returns (bytes memory) {
        return bytes.concat(script1, script2, script3);
    }
}
