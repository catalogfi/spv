
mod rpc_call_to_get_transactions;
mod rpc_call_to_get_blockheader;
mod merkle_proof;


#[allow(dead_code,unused_imports)]
use rpc_call_to_get_transactions::call_rpc_for_transactions;
#[allow(dead_code,unused_imports)]
use rpc_call_to_get_blockheader::call_rpc_for_blockheader;
#[allow(dead_code,unused_imports)]
use merkle_proof::generate_merkle_proof;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // pass the blockhash you want to get the data
    // call_rpc_for_blockheader("655be392b00d00cc79697217f1c006c730dc248485561e79829759b892c80d6d").await?;

    // call_rpc_for_transactions("73b95862cfc59e58af9178dcc78c86b9cbbd20245a0b576eeb7f91bc32fc314f")
    //     .await?;

    // generate_merkle_proof("173166296e3f9ef2a6dec5e1e288f7001423b8db9654a30d29999cc2a0c64e4d", "9b218523ddcbf6cd03c2813516f4b63267061131511364a2bf195b27c5ce016c")?;

    Ok(())
}
