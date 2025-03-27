use reqwest;
use serde::{Deserialize, Serialize};
use serde_json::{self, Value};
use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;

#[derive(Serialize, Deserialize, Debug)]
pub struct BlockTransactions {
    pub blockhash: String,
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
    pub params: Vec<String>,
    pub id: String,
}

fn reverse_hex(hex: &str) -> String {
    hex::decode(hex)
        .ok()
        .map(|bytes| {
            bytes.chunks(1)
                .rev()
                .flat_map(|b| b.iter())
                .map(|b| format!("{:02x}", b))
                .collect::<String>()
        })
        .unwrap_or_else(|| hex.to_string())
}

pub async fn call_rpc_for_transactions(blockhash: &str) -> Result<(), Box<dyn std::error::Error>> {
    let request_body = Request {
        jsonrpc: "1.0".to_string(),
        id: "curltest".to_string(),
        method: "getblock".to_string(),
        params: vec![blockhash.to_string()],
    };

    let client = reqwest::Client::new();
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
            .map(|s| format!("0x{}", reverse_hex(s)))  
            .collect()
    }),
    _ => None,
};

if let Some(tx_list) = transactions {
    let block_data = BlockTransactions {
        blockhash: format!("0x{}", reverse_hex(blockhash)),  
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
