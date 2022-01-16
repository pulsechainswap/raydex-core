// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./RayPair.sol";

contract GenerateHash {
    function getInitHash() public pure returns (bytes32) {
        bytes memory bytecode = type(RayPair).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }
}
