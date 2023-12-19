use dep::std;

struct State {
    pubkey_x: Field,
    pubkey_y: Field,
    balance: Field,
    nonce: Field,
}

struct Tx {
    from_x: Field,
    from_y: Field,
    to_x: Field,
    to_y: Field,
    value: Field,
    fee: Field,
    nonce: Field,
    signature_s: Field,
    signature_r8_x: Field,
    signature_r8_y: Field,
}

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
    // Verify state

    let state_from_hash = std::hash::pedersen_hash([state_from.pubkey_x, state_from.pubkey_y, state_from.balance, state_from.nonce]);
    let state_from_root = std::merkle::compute_merkle_root(state_from_hash, state_from_index, state_from_hashpath);
    assert(state_from_root == state_root);

    let state_to_hash = std::hash::pedersen_hash([state_to.pubkey_x, state_to.pubkey_y, state_to.balance, state_to.nonce]);
    let state_to_root = std::merkle::compute_merkle_root(state_to_hash, state_to_index, state_to_hashpath);
    assert(state_to_root == state_root);

    // Verify tx

    assert(tx.from_x == state_from.pubkey_x);
    assert(tx.from_y == state_from.pubkey_y);
    assert(tx.to_x == state_to.pubkey_x);
    assert(tx.to_y == state_to.pubkey_y);

    let tx_message_hash = std::hash::hash_to_field([tx.from_x, tx.from_y, tx.to_x, tx.to_y, tx.value, tx.fee, tx.nonce]);
    let tx_hash = std::hash::pedersen_hash([tx_message_hash, tx.signature_s, tx.signature_r8_x, tx.signature_r8_y]);
    let tx_root_check = std::merkle::compute_merkle_root(tx_hash, tx_index, tx_hashpath);
    assert(tx_root_check == tx_root);

    let signature_valid = std::eddsa::eddsa_poseidon_verify(
        tx.from_x,
        tx.from_y,
        tx.signature_s,
        tx.signature_r8_x,
        tx.signature_r8_y,
        tx_message_hash
    );
    assert(signature_valid);

    assert(tx.value as u64 + tx.fee as u64 <= state_from.balance as u64); // TODO: Check value fits in u64
    assert(tx.nonce == state_from.nonce);

    // Verify post-state

    let post_state_from = State {
        pubkey_x: state_from.pubkey_x,
        pubkey_y: state_from.pubkey_y,
        balance: state_from.balance - tx.value - tx.fee,
        nonce: state_from.nonce + 1
    };
    let post_state_from_hash = std::hash::pedersen_hash([post_state_from.balance, post_state_from.nonce]);
    let post_state_from_root = std::merkle::compute_merkle_root(post_state_from_hash, state_from_index, state_from_hashpath);
    assert(post_state_from_root == post_state_root);

    let post_state_to = State {
        pubkey_x: state_to.pubkey_x,
        pubkey_y: state_to.pubkey_y,
        balance: state_to.balance + tx.value,
        nonce: state_to.nonce
    };
    let post_state_to_hash = std::hash::pedersen_hash([post_state_to.balance, post_state_to.nonce]);
    let post_state_to_root = std::merkle::compute_merkle_root(post_state_to_hash, state_to_index, state_to_hashpath);
    assert(post_state_to_root == post_state_root);

    let post_state_miner = State {
        pubkey_x: state_miner.pubkey_x,
        pubkey_y: state_miner.pubkey_y,
        balance: state_miner.balance + tx.fee,
        nonce: state_miner.nonce
    };
    let post_state_miner_hash = std::hash::pedersen_hash([post_state_miner.balance, post_state_miner.nonce]);
    let post_state_miner_root = std::merkle::compute_merkle_root(post_state_miner_hash, state_miner_index, state_miner_hashpath);
    assert(post_state_miner_root == post_state_root);
}

#[test]
fn test_main() {
    // main(1, 2);
    // Uncomment to make test fail
    // main(1, 1);
}
