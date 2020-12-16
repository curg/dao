// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./CGT.sol";


contract Random {
    uint256 private seed;
    uint256 private recentRandomNumber;

    struct Participant {
        
    }


    function random(
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
