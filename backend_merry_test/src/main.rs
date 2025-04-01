mod rpc_call_to_get_blockheader;
mod rpc_call_to_get_transactions;

#[allow(dead_code, unused_imports)]
use rpc_call_to_get_blockheader::call_rpc_for_blockheaders;
#[allow(dead_code, unused_imports)]
use rpc_call_to_get_transactions::call_rpc_for_transactions;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // pass the blockhash you want to get the data
    // call_rpc_for_blockheaders(200,217).await?;

    call_rpc_for_transactions(211)
        .await?;

    // generate_merkle_proof("173166296e3f9ef2a6dec5e1e288f7001423b8db9654a30d29999cc2a0c64e4d", "9b218523ddcbf6cd03c2813516f4b63267061131511364a2bf195b27c5ce016c")?;

    Ok(())
}
