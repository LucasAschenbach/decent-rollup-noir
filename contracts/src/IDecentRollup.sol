// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IVerifier.sol";

abstract contract IDecentRollup {
    struct Batch {
        bytes32 txHash;
        address submitter;
        uint96 blockNumber;
    }

    struct Transition {
        bytes32 prevStateHash;
        bytes32 stateHash;
        address submitter;
    }

    uint256 public constant EXCLUSIVE_WINDOW = 20; // ~5 minutes
    uint256 public constant STAKE_AMOUNT = 1 ether;

    IMerkleVerifier public mv;
    IBatchVerifier public bv;

    bytes32 public stateHash;
    uint256 public batchIndex;
    Batch[] public batches;
    mapping(uint256 => Transition) public transitions;

    /**
     * @dev Submit a batch of transactions to the rollup chain.
     * @param _batch The batch of transactions to submit.
     */
    function submitBatch(bytes32 _root, bytes calldata _proof, bytes calldata _batch) external payable virtual;

    /**
     * @dev Verify self-submitted batch of transactions.
     * @param _batchIndex The index of the batch to verify.
     * @param _prevStateHash The state hash before the batch was submitted.
     * @param _stateHash The state hash after the batch was submitted.
     * @param _proof The proof of the batch's validity.
     * @return Whether or not the batch is valid.
     */
    function verifyBatch(uint256 _batchIndex, bytes32 _prevStateHash, bytes32 _stateHash, bytes memory _proof) external virtual returns (bool);

    /**
     * @dev Verify a batch of transactions from a foreign submitter after the exclusive window has passed.
     * @param _batchIndex The index of the batch to verify.
     * @param _proof The proof of the batch's validity.
     */
    function verifyForeignBatch(uint256 _batchIndex, bytes32 _prevStateHash, bytes32 _stateHash, bytes memory _proof) external virtual returns (bool);

    /**
     * @dev Skip a batch of transactions after the exclusive window has passed, burning the submitter's stake.
     * @param _batchIndex The index of the batch to skip.
     */
    function skipFraudulentBatch(uint256 _batchIndex) external virtual;
}
