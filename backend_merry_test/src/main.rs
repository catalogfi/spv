
mod rpc_call_to_get_transactions;
mod rpc_call_to_get_blockheader;
mod merkle_proof;


use rpc_call_to_get_transactions::call_rpc_for_transactions;
use rpc_call_to_get_blockheader::call_rpc_for_blockheader;
use merkle_proof::generate_merkle_proof;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // pass the blockhash you want to get the data
    // call_rpc_for_blockheader("54e5f935cb2219e9faa54a6f01d6e3d16a6355ee86fe8a067ef6b5add49e7aa9").await?;

    // call_rpc_for_transactions("173166296e3f9ef2a6dec5e1e288f7001423b8db9654a30d29999cc2a0c64e4d")
    //     .await?;

    generate_merkle_proof("0x4d4ec6a0c29c99290da35496dbb8231400f788e2e1c5dea6f29e3f6e29663117", "0x6c01cec5275b19bfa26413513111066732b6f4163581c203cdf6cbdd2385219b")?;

    Ok(())
}
