use dep::std;
use dep::rollup_lib::transition::{State, Tx, verify_transition};

fn main(
    state_from: State,
    state_from_index: Field,
    state_from_hashpath: [Field; 160], // Eth Address-space 2^160
    state_to: State,
    state_to_index: Field,
    state_to_hashpath: [Field; 160], // Eth Address-space 2^160
    state_miner: State,
    state_miner_index: Field,
    state_miner_hashpath: [Field; 160], // Eth Address-space 2^160
    state_root: pub Field,
    tx: Tx,
    tx_index: Field,
    tx_hashpath: [Field; 32], // 2^32 = 4294967296 max TXs/Batch
    tx_root: pub Field,
    post_state_root: pub Field
) {
    verify_transition(
        state_from,
        state_from_index,
        state_from_hashpath,
        state_to,
        state_to_index,
        state_to_hashpath,
        state_miner,
        state_miner_index,
        state_miner_hashpath,
        state_root,
        tx,
        tx_index,
        tx_hashpath,
        tx_root,
        post_state_root
    );
}

#[test]
fn test_main() {
    // main(1, 2);
    // Uncomment to make test fail
    // main(1, 1);
}
