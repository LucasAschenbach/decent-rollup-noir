// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IDecentRollup.sol";

contract DecentRollup is IDecentRollup {
    constructor(
        address _mv,
        address _bv
    ) {
        mv = IMerkleVerifier(_mv);
        bv = IBatchVerifier(_bv);
    }

    /// FUNCTIONS ///

    function submitBatch(bytes32 _root, bytes memory _proof, bytes calldata _batch) external payable override {
        require(msg.value == STAKE_AMOUNT, "Invalid stake amount");
        require(mv.verify(_proof), "Invalid proof"); // TODO: add _root as public input to proof
        batches.push(Batch({
            txHash: _root,
            submitter: msg.sender,
            blockNumber: uint96(block.number)
        }));
    }

    function verifyBatch(uint256 _batchIndex, bytes32 _prevStateHash, bytes32 _stateHash, bytes memory _proof) external override returns (bool) {
        Batch storage batch = batches[_batchIndex];
        require(batch.submitter == msg.sender, "Invalid submitter");

        return _verify(_batchIndex, _prevStateHash, _stateHash, _proof);
    }

    function verifyForeignBatch(uint256 _batchIndex, bytes32 _prevStateHash, bytes32 _stateHash, bytes memory _proof) external override returns (bool) {
        Batch storage batch = batches[_batchIndex];
        require(batch.submitter != msg.sender, "Invalid submitter");
        require(block.number > batch.blockNumber + EXCLUSIVE_WINDOW, "Batch is still in exclusive window");

        return _verify(_batchIndex, _prevStateHash, _stateHash, _proof);
    }

    function skipFraudulentBatch(uint256 _batchIndex) external override {
        Batch storage batch = batches[_batchIndex];
        require(batch.submitter != msg.sender, "Invalid submitter");
        require(block.number > batch.blockNumber + EXCLUSIVE_WINDOW, "Batch is still in exclusive window");

        delete batches[_batchIndex];
    }

    /// INTERNAL FUNCTIONS ///

    function _verify(uint256 _batchIndex, bytes32 _prevStateHash, bytes32 _stateHash, bytes memory _proof) internal returns (bool) {
        require(bv.verify(_proof), "Invalid proof");
        delete batches[_batchIndex];
        if (_batchIndex == batchIndex + 1) {
            // 1. all previous transitions are valid, update state hash
            require(_prevStateHash == stateHash, "Invalid previous state hash");
            batchIndex = _batchIndex;
            stateHash = _stateHash;
            uint256 index = _batchIndex + 1;
            bytes32 prevHash = _stateHash;
            while (transitions[index].submitter != address(0)) {
                address submitter = transitions[index].submitter;
                if (transitions[index].prevStateHash == prevHash) {
                    // 1.1 transition proof is consistent with previous transitions
                    batchIndex = index;
                    prevHash = transitions[index].stateHash;
                    delete transitions[index];
                    payable(submitter).transfer(STAKE_AMOUNT);
                } else {
                    // 1.2 transition proof starts from incorrect state, burn submitter's stake
                    batchIndex = index;
                    delete transitions[index];
                    payable(address(0)).transfer(STAKE_AMOUNT);
                }
                index++;
            }
            payable(msg.sender).transfer(STAKE_AMOUNT);
        } else {
            // 2. transition history has not been fully verified, save transition
            transitions[_batchIndex] = Transition({
                prevStateHash: _prevStateHash,
                stateHash: _stateHash,
                submitter: msg.sender
            });
        }
        
        return true;
    }

    function _skip(uint256 _batchIndex) internal {
        delete batches[_batchIndex];
    }
}
