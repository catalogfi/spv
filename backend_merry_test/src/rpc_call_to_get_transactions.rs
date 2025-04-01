use reqwest;
use serde::{Deserialize, Serialize};
use serde_json::{self, Value};
use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;

#[derive(Serialize, Deserialize, Debug)]
pub struct BlockTransactions {
    pub blockhash: String,
    pub blockheight: u64,
    pub transactions: Vec<String>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BitcoinRpcResponse {
    pub result: Value,
    pub error: Option<Value>,
    pub id: String,
}

#[derive(Serialize, Deserialize)]
pub struct Request {
    pub jsonrpc: String,
    pub method: String,
    pub params: Vec<Value>,
    pub id: String,
}

/// Reverse a hex string to handle endian conversion
fn reverse_hex(hex: &str) -> String {
    hex::decode(hex)
        .map(|mut bytes| {
            bytes.reverse();
            hex::encode(bytes)
        })
        .unwrap_or_else(|_| hex.to_string())
}

pub async fn call_rpc_for_transactions(blockheight: u64) -> Result<(), Box<dyn std::error::Error>> {
    // First, get the block hash from the block height
    let hash_request_body = Request {
        jsonrpc: "1.0".to_string(),
        id: "curltest".to_string(),
        method: "getblockhash".to_string(),
        params: vec![Value::from(blockheight)],
    };

    let client = reqwest::Client::new();
    let hash_res = client
        .post("http://localhost:18443")
        .basic_auth("admin1".to_owned(), Some("123".to_owned()))
        .json(&hash_request_body)
        .send()
        .await?;

    let hash_response_text = hash_res.text().await?;
    let hash_parsed_response: BitcoinRpcResponse = serde_json::from_str(&hash_response_text)?;

    let blockhash = match hash_parsed_response.result {
        Value::String(hash) => hash,
        _ => {
            eprintln!("Failed to retrieve block hash");
            return Ok(());
        }
    };

    // Now get the block details
    let request_body = Request {
        jsonrpc: "1.0".to_string(),
        id: "curltest".to_string(),
        method: "getblock".to_string(),
        params: vec![Value::from(blockhash.clone())],
    };

    let res = client
        .post("http://localhost:18443")
        .basic_auth("admin1".to_owned(), Some("123".to_owned()))
        .json(&request_body)
        .send()
        .await?;

    let response_text = res.text().await?;
    println!("Response received: {}", response_text);

    let parsed_response: BitcoinRpcResponse = serde_json::from_str(&response_text)?;

    let transactions = match parsed_response.result {
        Value::Object(ref obj) => obj.get("tx").and_then(|v| v.as_array()).map(|txs| {
            txs.iter()
                .filter_map(|tx| tx.as_str())
                .map(|s| reverse_hex(s)) // Convert to little-endian before storing
                .collect()
        }),
        _ => None,
    };

    if let Some(tx_list) = transactions {
        let block_data = BlockTransactions {
            blockhash: reverse_hex(&blockhash), // Convert blockhash to little-endian before storing
            blockheight,
            transactions: tx_list,
        };

        let file_path = "block_transactions.json";
        let mut records: Vec<BlockTransactions> = if Path::new(file_path).exists() {
            let mut file = File::open(file_path)?;
            let mut contents = String::new();
            file.read_to_string(&mut contents)?;

            if contents.trim().is_empty() {
                Vec::new()
            } else {
                serde_json::from_str(&contents).unwrap_or_else(|_| Vec::new())
            }
        } else {
            Vec::new()
        };

        records.push(block_data);
        let json_string = serde_json::to_string_pretty(&records)?;

        let mut file = File::create(file_path)?;
        file.write_all(json_string.as_bytes())?;

        println!("Successfully saved block transactions to {}", file_path);
    } else {
        eprintln!("Failed to extract transactions from response");
    }
    Ok(())
}
