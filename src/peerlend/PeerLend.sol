// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IVerifySPV, BlockHeader, Prevout, Outpoint} from "../interfaces/IVerifySPV.sol";
import {Bytes} from "@openzeppelin/contracts/utils/Bytes.sol";

contract BitcoinAdapterPL {
    using Bytes for bytes;

    IVerifySPV spv;

    // Mapping of approved bitcoin addresses to loan amounts
    mapping(bytes32 => uint256) public approvedLoans;
    
    // Mapping to track if a bitcoin UTXO has been used
    mapping(bytes32 => bool) public usedUTXOs;

    // Event emitted when a loan is taken
    event LoanTaken(address borrower, uint256 amount, bytes32 btcAddress);

    constructor(address _spv) {
        spv = IVerifySPV(_spv);
    }

    // Admin function to approve bitcoin addresses for loans
    function approveLoan(bytes20 btcAddress, uint256 amount) external {
        // TODO: Add access control
        approvedLoans[btcAddress] = amount;
    }

    /**
     * @notice Allows a user to borrow funds by proving they control an approved Bitcoin address
     * @param blockSequence Array of block headers containing the funding tx
     * @param txHex Raw Bitcoin transaction bytes
     * @param blockIndex Index of block containing tx in sequence
     * @param txIndex Index of tx in block
     * @param proof Merkle proof of tx inclusion
     */
    function borrow(
        BlockHeader[] calldata blockSequence,
        bytes calldata txHex,
        uint256 blockIndex, 
        uint256 txIndex,
        uint256 opIndex,
        bytes32[] memory proof
    ) external {
        // Verify the Bitcoin transaction
        (uint256 confirmations, bytes32 txHash,, Outpoint[] memory outPoints) = 
            spv.parseAndVerifyTxInclusion(
                blockSequence,
                txHex,
                blockIndex,
                txIndex,
                proof
            );

        require(confirmations >= 6, "Insufficient confirmations");
        require(!usedUTXOs[keccak256(abi.encodePacked(txHash, opIndex))], "UTXO already used");

        // Extract the recipient Bitcoin address from output
        // Assuming P2PKH output format
        require(outPoints.length > 0, "No outputs found");

        Outpoint memory op = outPoints[opIndex];
        bytes32 pubkeyHash = bytes32(op.spk.slice(3));
        
        uint256 loanAmount = approvedLoans[pubkeyHash];
        require(loanAmount > 0, "Bitcoin address not approved for loan");

        // Mark UTXO as used
        usedUTXOs[keccak256(abi.encodePacked(txHash, opIndex))] = true;

        // Transfer loan amount to borrower
        // TODO: Add actual token transfer logic
        
        emit LoanTaken(msg.sender, loanAmount, pubkeyHash);
    }


    mapping (bytes20 => uint) name;
}
