// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBatchVerifier {
    function verify(bytes calldata _proof) external view returns (bool);
}

interface IMerkleVerifier {
    function verify(bytes calldata _proof) external view returns (bool);
}
