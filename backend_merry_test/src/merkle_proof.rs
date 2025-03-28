use serde::{Deserialize, Serialize};
use serde_json;
use sha2::{Digest, Sha256};
use std::fs::File;
use std::io::{Read, Write};

#[derive(Serialize, Deserialize, Debug)]
struct BlockTransactions {
    blockhash: String,
    transactions: Vec<String>,
}

#[derive(Serialize, Deserialize, Debug)]
struct MerkleProof {
    transaction: String,
    proof: Vec<String>,
}

/// Performs double SHA-256 hashing on a byte slice
fn double_sha256(bytes: &[u8]) -> Vec<u8> {
    let hash1 = Sha256::digest(bytes);
    let hash2 = Sha256::digest(&hash1);
    hash2.to_vec()
}

/// Generates a Merkle proof for a specific transaction in a block
pub fn generate_merkle_proof(blockhash: &str, txid: &str) -> Result<(), Box<dyn std::error::Error>> {
    // Read the block transactions from the JSON file
    let mut file = File::open("block_transactions.json")?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    
    let blocks: Vec<BlockTransactions> = serde_json::from_str(&contents)?;
    
    let block = blocks.iter().find(|b| b.blockhash == blockhash)
        .ok_or_else(|| "Block not found".to_string())?;
    
    let tx_index = block.transactions.iter().position(|t| t == txid)
        .ok_or_else(|| "Transaction not found in block".to_string())?;

    // Convert transactions to raw bytes before hashing
    let mut hashes: Vec<Vec<u8>> = block.transactions
        .iter()
        .map(|tx| hex::decode(tx).expect("Invalid hex input"))
        .map(|bytes| double_sha256(&bytes))
        .collect();
    
    let mut proof = Vec::new();
    let mut current_index = tx_index;

    while hashes.len() > 1 {
        if hashes.len() % 2 == 1 {
            hashes.push(hashes.last().unwrap().clone());
        }
        
        let mut next_level = Vec::new();
        for i in (0..hashes.len()).step_by(2) {
            let left = &hashes[i];
            let right = &hashes[i + 1];

            if current_index == i {
                proof.push(hex::encode(right));
            } else if current_index == i + 1 {
                proof.push(hex::encode(left));
            }

            let mut combined = Vec::new();
            combined.extend(left);
            combined.extend(right);
            let parent_hash = double_sha256(&combined);
            next_level.push(parent_hash);
        }

        current_index /= 2;
        hashes = next_level;
    }

    let proof_data = MerkleProof {
        transaction: txid.to_string(),
        proof,
    };

    let proof_json = serde_json::to_string_pretty(&proof_data)?;
    let mut proof_file = File::create("merkle_proof.json")?;
    proof_file.write_all(proof_json.as_bytes())?;

    println!("Merkle proof generated successfully");
    Ok(())
}
