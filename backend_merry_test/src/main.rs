use reqwest;
use serde::{Deserialize, Serialize};
use serde_json::{self, Value};
use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;

#[derive(Serialize, Deserialize, Debug)]
pub struct Blockheader {
    pub version: String,
    pub previousblockhash: String,
    pub merkleroot: String,
    pub time: String,
    pub bits: String,
    pub nonce: String,
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

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let request_body = Request {
        jsonrpc: "1.0".to_string(),
        id: "curltest".to_string(),
        method: "getblock".to_string(),
        params: vec![
            "11f0d9573a448b6b1ff936e962d826629367149b4be66f70f0e42c47201d01bd".to_string(),
        ],
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

    let block_data = match parsed_response.result {
        Value::Object(ref obj) => {
            let blockheader = Blockheader {
                version: format!(
                    "0x{:x}",
                    obj.get("version").and_then(|v| v.as_u64()).unwrap_or(0)
                ),
                previousblockhash: format!(
                    "0x{}",
                    obj.get("previousblockhash")
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                ),
                merkleroot: format!(
                    "0x{}",
                    obj.get("merkleroot").and_then(|v| v.as_str()).unwrap_or("")
                ),
                time: format!(
                    "0x{:x}",
                    obj.get("time").and_then(|v| v.as_u64()).unwrap_or(0)
                ),
                bits: format!(
                    "0x{}",
                    obj.get("bits").and_then(|v| v.as_str()).unwrap_or("")
                ),
                nonce: format!(
                    "0x{:x}",
                    obj.get("nonce").and_then(|v| v.as_u64()).unwrap_or(0)
                ),
            };
            Some(blockheader)
        }
        _ => None,
    };

    if let Some(header) = block_data {
        let file_path = "blockheader.json";
        let mut headers: Vec<Blockheader> = if Path::new(file_path).exists() {
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

        headers.push(header);
        let json_string = serde_json::to_string_pretty(&headers)?;

        let mut file = File::create(file_path)?;
        file.write_all(json_string.as_bytes())?;

        println!("Successfully saved block header to {}", file_path);
    } else {
        eprintln!("Failed to extract block header from response");
    }

    Ok(())
}
