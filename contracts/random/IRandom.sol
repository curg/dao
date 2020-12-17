// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Abstarct contract of the Random contract.
 */
abstract contract IRandom {
    event RandomNumber(uint256 randomNumber_);

    /** 
     * @dev Computes and returns the random number.
     */
    function random(
        uint256 campaignNum // like seed
    ) public virtual returns (
        uint256 randomNumber
    );
}
