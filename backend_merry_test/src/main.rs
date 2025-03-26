
mod rpc_call_for_transactions;
mod rpc_call_to_get_blockheader;

use rpc_call_for_transactions::{call_rpc_for_transactions, get_merkle_leaf};
use rpc_call_to_get_blockheader::call_rpc_for_blockheader;
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // pass the blockhash you want to get the data
    // call_rpc_for_blockheader("7c30117758f9414720101e94b308dab45e3d0c7baaa7a6a9178e9fa21a6528f8").await?;

    call_rpc_for_transactions("18ab8e1a9bf1d5d0309783bc61b24a49786d8e46b5a07c60d44c06bb0729092a")
        .await?;

    // let x = get_merkle_leaf("18ab8e1a9bf1d5d0309783bc61b24a49786d8e46b5a07c60d44c06bb0729092a", "fb24b20d7bb07b7735f67767af1f279bc283ebce37bf6f10cad0f4440670bd38").await;
    // println!("{:?}", x);

    Ok(())
}
