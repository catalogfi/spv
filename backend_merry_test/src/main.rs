
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

    call_rpc_for_transactions("173166296e3f9ef2a6dec5e1e288f7001423b8db9654a30d29999cc2a0c64e4d")
        .await?;

    // generate_merkle_proof("173166296e3f9ef2a6dec5e1e288f7001423b8db9654a30d29999cc2a0c64e4d", "9b218523ddcbf6cd03c2813516f4b63267061131511364a2bf195b27c5ce016c")?;

    Ok(())
}
