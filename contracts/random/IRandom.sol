// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;


/**
 * @dev Abstarct contract of the Random contract.
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
abstract contract Random {
    function defaultRandom(
    ) returns (
        uint256 defaultRandom_
    );

    function createCampaign(
        uint256 timeLimit
    ) public virtual returns (
        uint256 campaignNum_
    );

    function joinAt(
        uint256 campaignNum
    ) public virtual returns (bool);

    function revealAt(
        uint256 campaignNum
    ) public virtual returns (bool);

    /** 
     * @dev Computes and returns the random number.
     */
    function getRandomAt(
        uint256 campaignNum
    ) public virtual returns (
        uint256 randomNumber
    );

    function totalCampaigns(
        // ...
    ) public view virtual returns (
        uint256 length_
    );

    event;
}
