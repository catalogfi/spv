// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IVerifySPV, ISPV, SPVCallback} from "./interfaces/IVerifySPV.sol";
import {LibSPV} from "./libraries/LibSPV.sol";
import {BlockHeader, Prevout, Outpoint, LibBitcoin} from "./libraries/LibBitcoin.sol";
import {Bytes} from "@openzeppelin/contracts/utils/Bytes.sol";

struct BlockRecord {
    BlockHeader header;
    uint256 confidence;
    uint256 height;
}

contract VerifySPV is IVerifySPV {
    using LibSPV for BlockHeader;
    using LibBitcoin for bytes;

    mapping(bytes32 => BlockRecord) public blockHeaders;
    // reverse mapping for block number to block hashes
    mapping(uint256 => bytes32) public blockHashes;
    // every difficulty epoch's block hash
    // updates for every 2016th block = every 28 epochs
    bytes32 public LDEBlockHash;

    bytes32 public LatestBlockHash;

    uint256 public minimumConfidence;

    bool public isTestnet;

    event BlockRegistered(bytes32 indexed blockHash, uint256 indexed height);

    // @dev Constructor to initialize the contract with the genesis block
    // @dev Genesis block here means the first block in the SPV system
    // @param genesisHeader - BlockHeader of the genesis block
    // @param height - Height of the genesis block
    // @param _minimumConfidence - Minimum number of blocks required to consider the latest block as confirmed
    // @param _isTestnet - Boolean indicating if the chain is a testnet
    // @notice The genesis block should be at the start of a difficulty epoch => height % 2016 == 0
    constructor(
        BlockHeader memory genesisHeader,
        uint256 height,
        uint256 _minimumConfidence,
        bool _isTestnet
    ) {
        require(
            _isTestnet || height % 2016 == 0,
            "VerifySPV: genesis block should be at the start of a difficulty epoch"
        );
        LDEBlockHash = genesisHeader.calculateBlockHash();
        LatestBlockHash = LDEBlockHash;
        blockHeaders[LDEBlockHash] = BlockRecord({
            header: genesisHeader,
            confidence: 0,
            height: height
        });
        blockHashes[height] = LDEBlockHash;
        minimumConfidence = _minimumConfidence;
        isTestnet = _isTestnet;
    }

    // @dev Register a new block on the chain
    // @param newEpoch - Array of block headers for the new epoch
    // @param blockIndex - Index of the block to be registered in the new epoch
    // @notice The blockIndex should be greater than 0 and less than the length of the newEpoch array
    // @notice The newEpoch array should contain the current block and atleast minimumConfidence number of blocks
    // @notice The newEpoch array should not contain more than 2016 blocks
    // @notice The starting block of the newEpoch should be the latest block hash
    // @notice To register a new block from new difficulty epoch, the first block of the newEpoch should be registered first
    function registerLatestBlock(
        BlockHeader[] calldata newEpoch,
        uint256 blockIndex
    ) public {
        require(
            blockIndex < newEpoch.length && blockIndex > 0,
            "VerifySPV: invalid block index"
        );
        require(
            newEpoch.length >= blockIndex + minimumConfidence + 1,
            "VerifySPV: invalid epoch, should contain the current block and atleast next block"
        );

        require(
            newEpoch.length <= 2016 + minimumConfidence + 1,
            "VerifySPV: invalid epoch, should not contain more than 2016 blocks"
        );

        require(
            newEpoch[0].calculateBlockHash() == LatestBlockHash,
            "VerifySPV: invalid epoch, starting block not on chain"
        );

        uint256 newHeight = blockHeaders[LatestBlockHash].height + blockIndex;

        require(
            isTestnet ||
                newHeight % 2016 == 0 ||
                (newHeight % 2016 != 0 &&
                    blockHashes[(newHeight / 2016) * 2016] == LDEBlockHash),
            "VerifySPV: invalid epoch, last difficulty epoch block should be regostered before following blocks"
        );

        require(
            blockHashes[newHeight] == bytes32(0x0),
            "VerifySPV: block already registered"
        );

        verifySequence(newEpoch, newHeight, blockIndex);

        bytes32 newEpochBlockHash = newEpoch[blockIndex].calculateBlockHash();
        blockHeaders[newEpochBlockHash] = BlockRecord({
            header: newEpoch[blockIndex],
            confidence: newEpoch.length - blockIndex - 1,
            height: newHeight
        });

        LatestBlockHash = newEpochBlockHash;

        if (newHeight % 2016 == 0) {
            LDEBlockHash = newEpochBlockHash;
        }

        blockHashes[newHeight] = newEpochBlockHash;

        emit BlockRegistered(newEpochBlockHash, newHeight);
    }

    // @dev Register a block between two blocks already on the chain
    // @param blockSequence - Array of block headers for the new epoch
    // @param blockIndex - Index of the block to be registered in the new epoch
    // @notice The intended block should be between the first and last block of the blockSequence
    // @notice This can be used to optimize the gas cost of verify function if demand for number of
    // @notice tx inclusion proofs are higer between two already registered blocks which are undesirably far in height.
    function registerInclusiveBlock(
        BlockHeader[] calldata blockSequence,
        uint256 blockIndex
    ) public {
        require(
            blockIndex < blockSequence.length,
            "VerifySPV: invalid block index"
        );

        require(
            blockHeaders[blockSequence[0].calculateBlockHash()].height != 0,
            "VerifySPV: invalid epoch, starting block not on chain"
        );

        require(
            blockHeaders[
                blockSequence[blockSequence.length - 1].calculateBlockHash()
            ].height != 0,
            "VerifySPV: invalid epoch, ending block not on chain"
        );

        verifySequence(
            blockSequence,
            blockHeaders[blockSequence[0].calculateBlockHash()].height +
                blockIndex,
            blockIndex
        );

        LatestBlockHash = blockSequence[blockIndex].calculateBlockHash();
        blockHashes[
            blockHeaders[blockSequence[0].calculateBlockHash()].height +
                blockIndex
        ] = LatestBlockHash;
    }

    // @dev Verify the inclusion of a transaction in a block
    // @param blockSequence - Array of block headers between two blocks already on the chain
    // @param blockIndex - Index of the desired block in the blockSequence
    // @param txIndex - Index of the transaction in the block
    // @param txHash - Transaction hash to be verified
    // @param proof - Array of merkle proof hashes
    // @return confirmations - Uint256 indicating the number of confirmations of the block 
    function verifyTxInclusion(
        BlockHeader[] calldata blockSequence,
        uint256 blockIndex,
        uint256 txIndex,
        bytes32 txHash,
        bytes32[] memory proof
    ) public view returns (uint256) {
        require(
            blockIndex < blockSequence.length,
            "VerifySPV: invalid block index"
        );

        require(
            blockHeaders[blockSequence[0].calculateBlockHash()].height != 0,
            "VerifySPV: invalid epoch, starting block not on chain"
        );

        require(
            blockHeaders[
                blockSequence[blockSequence.length - 1].calculateBlockHash()
            ].height != 0,
            "VerifySPV: invalid epoch, starting block not on chain"
        );

        verifySequence(
            blockSequence,
            blockHeaders[blockSequence[0].calculateBlockHash()].height +
                blockIndex,
            blockIndex
        );

        uint256 prevBlockConfidence = confidenceByHash(blockSequence[blockIndex].previousBlockHash);
        require(prevBlockConfidence != 0, "VerifySPV: unconfirmed or unrelayed block");
        require(blockSequence[blockIndex].verifyProof(txHash, txIndex, proof), "VerifySPV: invalid tx inculsion proof");
        return prevBlockConfidence-1;
    }

    // @dev Parse and verify the inclusion of a transaction in a block
    // @param blockSequence - Array of block headers between two blocks already on the chain
    // @param txHex - Transaction in raw hex bytes to be verified
    // @param blockIndex - Index of the desired block in the blockSequence
    // @param txIndex - Index of the transaction in the block
    // @param proof - Array of merkle proof hashes
    // @return confirmations - Uint256 indicating the number of confirmations of the block 
    // @return txHash - Hash of the transaction
    // @return prevOuts - Array of previous outputs of inputs in the transaction
    // @return outPoints - Array of outputs of the transaction
    function parseAndVerifyTxInclusion(
        BlockHeader[] calldata blockSequence,
        bytes calldata txHex,
        uint256 blockIndex,
        uint256 txIndex,
        bytes32[] memory proof
    ) public view returns (uint256, bytes32, Prevout[] memory, Outpoint[] memory) {
        (
            bytes32 txHash,
            Prevout[] memory prevOuts,
            Outpoint[] memory outPoints
        ) = txHex.parseTx();

        return (
            verifyTxInclusion(
                blockSequence,
                blockIndex,
                txIndex,
                txHash,
                proof
            ),
            txHash,
            prevOuts,
            outPoints
        );
    }

    // @dev Get confidence of a block by its hash
    // @dev Confidence is the number of blocks after the block in the longest chain
    // @dev plus the minimum confidence used to consider the latest block as confirmed
    // @param blockHash - Hash of the block
    function confidenceByHash(bytes32 blockHash) public view returns (uint256) {
        require(
            blockHeaders[blockHash].height != 0,
            "VerifySPV: block not registered"
        );
        return
            blockHeaders[LatestBlockHash].confidence +
            (blockHeaders[LatestBlockHash].height -
                blockHeaders[blockHash].height);
    }

    // @dev Get confidence of a block by its height
    function confidenceByHeight(uint256 height) public view returns (uint256) {
        return confidenceByHash(blockHashes[height]);
    }

    function verifySequence(
        BlockHeader[] calldata blockSequence,
        uint256 height,
        uint256 blockIndex
    ) internal view {
        // Testnet3 difficulty adjustment is not as strict as mainnet
        // Testnet4 has different consensus rules
        if (isTestnet) {
            require(
                verifySubSequence(blockSequence, 1),
                "VerifySPV: sequence verification failed"
            );
        }

        uint256 epochDivider = blockSequence.length;
        if (height % 2016 == 0) {
            epochDivider = blockIndex;
        } else {
            uint256 overFlow = (height % 2016) +
                (blockSequence.length - blockIndex) -
                1;
            if (overFlow > 2015) {
                epochDivider -= (overFlow - 2015);
            }
        }

        uint256 target = (
            abi.encodePacked((blockHeaders[LDEBlockHash].header.nBits))
        ).convertnBitsToTarget();

        require(verifySubSequence(blockSequence[:epochDivider], target));
        if (epochDivider < blockSequence.length) {
            uint256 adjustedTarget = blockSequence[epochDivider]
                .calculateNewTarget(
                    target,
                    blockHeaders[LDEBlockHash].header.timestamp
                );
            uint256 newTarget = (
                abi.encodePacked((blockSequence[epochDivider].nBits))
            ).convertnBitsToTarget();
            require(
                LibSPV.verifyDifficultyEpochTarget(adjustedTarget, newTarget),
                "VerifySPV: adjusted difficulty is not in allowed range"
            );
            require(
                blockSequence[epochDivider - 1].calculateBlockHash() ==
                    blockSequence[epochDivider].previousBlockHash &&
                    blockSequence[epochDivider].verifyWork(),
                "VerifySPV: difficulty epoch validation failed"
            );
            require(
                verifySubSequence(blockSequence[epochDivider:], newTarget),
                "VerifySPV: post subsequence in difficulty epoch failed"
            );
        }
    }

    function verifySubSequence(
        BlockHeader[] calldata blockSequence,
        uint256 target
    ) internal view returns (bool) {
        for (uint256 i = 1; i < blockSequence.length; i++) {
            if (
                !(blockSequence[i - 1].calculateBlockHash() ==
                    blockSequence[i].previousBlockHash)
            ) {
                return false;
            }

            if (isTestnet) {
                return true;
            }
            if (
                !blockSequence[i].verifyTarget(target) &&
                blockSequence[i].verifyWork()
            ) {
                return false;
            }
        }

        return true;
    }

    enum BTCAddressType {
        P2PKH,      // Pay to Public Key Hash
        P2SH,       // Pay to Script Hash
        P2WPKH,     // Pay to Witness Public Key Hash
        P2WSH,      // Pay to Witness Script Hash
        P2TR        // Pay to Taproot
    }

    struct Callback {
        BTCAddressType addrType;
        SPVCallback callback;
        uint256 rewardPerCall;

        uint256 balance;
    }

    // Mapping to track if a bitcoin UTXO has been used
    mapping(bytes32 => bytes32) public deposits;

    // Mapping to track if a bitcoin UTXO has been used
    mapping(bytes32 => bytes32) public withdrawals;

    // Mapping from pubkeyhash to callback address
    mapping(bytes32 => Callback) public callbacks;

    event UTXOProcessed(bytes32 indexed txHash, uint256 indexed outputIndex, bytes32 indexed pubkeyHash, BTCAddressType addrType, uint256 amount);

    /**
     * @notice Registers a callback for when a Bitcoin transaction is processed
     * @param callback The address to call when a transaction is processed
     */
    function registerCallback(bytes calldata spk, SPVCallback callback, uint256 reward) external payable {
        (BTCAddressType addrType, bytes32 pubKeyHash) = extractFromScriptPubKey(spk);
        require(address(callbacks[pubKeyHash].callback) == address(0), "Callback already registered");
        callbacks[pubKeyHash] = Callback({
            addrType: addrType,
            rewardPerCall: reward,
            callback: callback,
            balance: msg.value
        });
    }

    /**
     * @notice Funds a callback to pay for rewards
     * @param pubKeyHash The Bitcoin public key hash associated with the callback
     */
    function fundCallback(bytes32 pubKeyHash) external payable {
        require(address(callbacks[pubKeyHash].callback) != address(0), "Callback not registered");
        
        callbacks[pubKeyHash].balance += msg.value;
    }

    /**
     * @notice Allows a user to borrow funds by proving they control an approved Bitcoin address
     * @param blockSequence Array of block headers containing the funding tx
     * @param txHex Raw Bitcoin transaction bytes
     * @param blockIndex Index of block containing tx in sequence
     * @param txIndex Index of tx in block
     * @param proof Merkle proof of tx inclusion
     */
    function submitTransaction(
        BlockHeader[] calldata blockSequence,
        bytes calldata txHex,
        uint256 blockIndex, 
        uint256 txIndex,
        uint256[] calldata ipIndexes,
        uint256[] calldata opIndexes,
        bytes32[] memory proof
    ) external {
        // Verify the Bitcoin transaction
        (uint256 confirmations, bytes32 txHash, Prevout[] memory prevOuts, Outpoint[] memory outPoints) = 
            parseAndVerifyTxInclusion(
                blockSequence,
                txHex,
                blockIndex,
                txIndex,
                proof
            );

        require(confirmations >= 6, "Insufficient confirmations");

        if (opIndexes.length > 0) {
            for (uint256 i = 0; i < opIndexes.length; i++) {
                uint256 opIndex = opIndexes[i];
                require(opIndex < outPoints.length, "Output index out of bounds");

                require(deposits[keccak256(abi.encodePacked(txHash, opIndex))] == bytes32(0x0), "UTXO already used");

                // Extract the recipient Bitcoin address from output
                // Assuming P2PKH output format
                require(outPoints.length > 0, "No outputs found");

                Outpoint memory op = outPoints[opIndex];
                (BTCAddressType addrType, bytes32 pubKeyHash) = extractFromScriptPubKey(op.spk);

                // Call registered callback if one exists
                Callback storage callback = callbacks[pubKeyHash];
                if (address(callback.callback) != address(0) && addrType == callback.addrType) {
                    callback.callback.onCreate(txHash, opIndex, op.amount);
                }

                // Mark UTXO as used
                deposits[keccak256(abi.encodePacked(txHash, opIndex))] = pubKeyHash;

                emit UTXOProcessed(txHash, opIndex, pubKeyHash, addrType, op.amount);
            }
        }

        if (ipIndexes.length > 0) {
            for (uint256 i = 0; i < ipIndexes.length; i++) {
                uint256 ipIndex = ipIndexes[i];
                require(ipIndex < prevOuts.length, "Input index out of bounds");
                Prevout memory prevout = prevOuts[ipIndex];

                bytes32 dpkh = deposits[keccak256(abi.encodePacked(prevout.txid, prevout.vout))];
                require(dpkh != bytes32(0x0), "UTXO has not been registered");

                // Call registered callback if one exists
                Callback storage callback = callbacks[dpkh];
                if (address(callback.callback) != address(0)) {
                    callback.callback.onSpend(prevout.txid, prevout.vout);
                }
            }
        }
    }


    /**
     * @notice Extracts the type and pubkeyhash from a Bitcoin scriptPubKey
     * @param spk The scriptPubKey bytes
     * @return addrType The type of Bitcoin address
     * @return pubkeyHash The extracted pubkeyhash/scripthash
     */
    function extractFromScriptPubKey(bytes memory spk) public pure returns (BTCAddressType addrType, bytes32 pubkeyHash) {
        // P2PKH: OP_DUP OP_HASH160 <20 bytes> OP_EQUALVERIFY OP_CHECKSIG
        if (spk.length == 25 && spk[0] == 0x76 && spk[1] == 0xa9 && spk[2] == 0x14 && spk[23] == 0x88 && spk[24] == 0xac) {
            return (BTCAddressType.P2PKH, bytes32(Bytes.slice(spk, 3, 23)));
        }
        
        // P2SH: OP_HASH160 <20 bytes> OP_EQUAL
        if (spk.length == 23 && spk[0] == 0xa9 && spk[1] == 0x14 && spk[22] == 0x87) {
            return (BTCAddressType.P2SH, bytes32(Bytes.slice(spk, 2, 22)));
        }

        // P2WPKH: OP_0 <20 bytes>
        if (spk.length == 22 && spk[0] == 0x00 && spk[1] == 0x14) {
            return (BTCAddressType.P2WPKH,  bytes32(Bytes.slice(spk, 2)));
        }

        // P2WSH: OP_0 <32 bytes>
        if (spk.length == 34 && spk[0] == 0x00 && spk[1] == 0x20) {
            return (BTCAddressType.P2WSH,  bytes32(Bytes.slice(spk, 2)));
        }

        // P2TR: OP_1 <32 bytes>
        if (spk.length == 34 && spk[0] == 0x01 && spk[1] == 0x20) {
            return (BTCAddressType.P2TR,  bytes32(Bytes.slice(spk, 2)));
        }

        revert("SPV: unsupported scriptPubKey");
    }
}

