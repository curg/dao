// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "../COMMITTEDAO.sol";
import "./IRandom.sol";


/**
 * @dev Contract module which calculates a random number via DAO.
 *
 * TODO:
 *
 * - adding VDF (verifiable delay functions) or VRF (verifiable random functions) .
 *
 * References:
 *
 * - https://github.com/randao/randao
 * - https://our.status.im/two-point-oh-randomness/
 */
contract RANDAO is Context, COMMITTEDAO, IRandom {
    uint256 private seed;

    constructor (
        // ...
    ) public {
        // TODO: MUST require staking to enter DAO.
        // ...
    }

    /**
     * @dev Adds more randomness and robustness.
     */
    function defaultRandom(
        // ...
    ) internal returns (
        uint256 randomNumber
    ) {
        randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            seed
        )));

        seed += 1;
    }

    /**
     * @dev Requests a random number.
     */
    function randomRequest(
        uint256 commitTimeLimit_,
        uint256 revealTimeLimit_
    ) public returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        // "random"
        bytes32 name_ = 0x72616e646f6d0000000000000000000000000000000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](0);

        return cSendRequest(name_, arguments_, commitTimeLimit_, revealTimeLimit_);
    }

    /**
     * @dev Gets the random number requested.
     */
    function random(
        uint256 campaignNum
    ) public override returns (
        uint256 randomNumber
    ) {
        // "random"
        bytes32 name_ = 0x72616e646f6d0000000000000000000000000000000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](0);

        randomNumber = cResolveRequest(name_, arguments_, key_);
        randomNumber ^= defaultRandom();

        emit RandomNumber(randomNumber);
    }

    /**
     * @dev Commits hidden number at the campaign.
     */
    function commitAt(
        uint256 campaignNum,
        bytes32 commitment_
    ) public returns (bool) {
        return _commitAt(campaignNum, commitment_);
    }

    /**
     * @dev Makes hidden number public with `secret_` and `seed_`.
     */
    function revealAt(
        uint256 campaignNum,
        uint256 secret_,
        uint256 seed_
    ) public returns (bool) {
        return _revealAt(campaignNum, secret_, seed_);
    }

    /**
     * @dev Votes the campaign.
     */
    function hiddenVoteAt(
        uint256 campaignNum,
        bytes32 commitment_
    ) public returns (bool) {
        return _hiddenVoteAt(campaignNum, commitment_);
    }

    /**
     * @dev Reveals vote.
     */
    function revealVoteAt(
        uint256 campaignNum,
        bool agree_,
        uint256 seed_
    ) public returns (bool) {
        // // TODO: Implement 'depositOf'.
        // address msgSender = _msgSender();

        // int256 weights_ = int256(depositOf(msgSender));
        // if (!agree_) {
        //     weights_ *= (-1);
        // }

        return _revealVoteAt(campaignNum, weights, seed_);
    }
}
