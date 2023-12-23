use dep::std;
use dep::rollup_lib::transition::{State, Tx, verify_transition};

fn main(
    verification_key: [Field; 114],
    proof: [Field; 94],
    key_hash: Field,
    input_aggregation_object: [Field; 16],
    initial_state_root: pub Field,
    state_from: State,
    state_from_index: Field,
    state_from_hashpath: [Field; 160], // Eth Address-space 2^160
    state_to: State,
    state_to_index: Field,
    state_to_hashpath: [Field; 160], // Eth Address-space 2^160
    state_miner: State,
    state_miner_index: Field,
    state_miner_hashpath: [Field; 160], // Eth Address-space 2^160
    state_root: Field,
    tx: Tx,
    tx_index: Field,
    tx_hashpath: [Field; 32], // 2^32 = 4294967296 max TXs/Batch
    tx_root: pub Field,
    post_state_root: pub Field
) -> pub [Field; 16] {
    // Recursively verify transition from initial_state_root to state_root

    let output_aggregation_object = std::verify_proof(
        verification_key.as_slice(),
        proof.as_slice(),
        [initial_state_root, tx_root, state_root].as_slice(),
        key_hash,
        input_aggregation_object
    );

    // Verify transition from state_root to post_state_root

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

    // Return output aggregation object for next recursion step

    let mut output = [0; 16];
    for i in 0..16 {
        output[i] = output_aggregation_object[i];
    }
    output
}

#[test]
fn test_main() {
    // main(1, 2);
    // Uncomment to make test fail
    // main(1, 1);
}
