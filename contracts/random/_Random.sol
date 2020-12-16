// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;


// WARNING: This contract is the temporary implementation of random.
// TODO: Using trustable random process for real uses.
contract Random {
    uint256 private seed;
    uint256 private recentRandomNumber;

    // {Random} contract MUST has {random} function.
    function getRandomAt(
        uint256 campaignNum;
    ) public returns (
        uint256 randomNumber
    ) {
        randomNumber = uint256(keccak256(
            abi.encodePacked(seed, block.timestamp, block.difficulty)
        ));
        recentRandomNumber = randomNumber;

        seed += 1;
    }
    
    function getRecentRandom() public view returns (uint256) {
        return recentRandomNumber;
    }
}
