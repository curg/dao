// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IRandom.sol";


// WARNING: This contract is the temporary implementation of random.
// Using trustable random process for real uses.
contract Random is IRandom {
    uint256 private seed;

    // {Random} contract MUST has {random} function.
    function random(
        uint256 campaignNum
    ) public override returns (
        uint256 randomNumber
    ) {
        randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            seed
        )));

        emit RandomNumber(randomNumber);

        seed += 1;
    }
}
