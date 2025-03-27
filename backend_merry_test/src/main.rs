
mod rpc_call_to_get_transactions;
mod rpc_call_to_get_blockheader;

use rpc_call_to_get_transactions::call_rpc_for_transactions;
use rpc_call_to_get_blockheader::call_rpc_for_blockheader;
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // pass the blockhash you want to get the data
    // call_rpc_for_blockheader("0a14b5bdf010bf3a147533bee4757683957533d6bc69589398cf2b672d04af6a").await?;

    call_rpc_for_transactions("768e6be748c56927007e91bacb2126eb993e5b9155c8a9502d9734e5cab88b03")
        .await?;

    // let x = get_merkle_leaf("18ab8e1a9bf1d5d0309783bc61b24a49786d8e46b5a07c60d44c06bb0729092a", "fb24b20d7bb07b7735f67767af1f279bc283ebce37bf6f10cad0f4440670bd38").await;
    // println!("{:?}", x);

    Ok(())
}
