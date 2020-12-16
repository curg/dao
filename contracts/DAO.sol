// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "openzeppelin-solidity/contracts/math/SignedSafeMath.sol";


/**
 * @dev Contract module which provides a Decentralized Autonomous Organization
 * (DAO) mechanism, where including the (weighted) voting system for governance.
 *
 * This module is used through inheritance. It will make available the modifier
 * `resolve(...)`, which can be applied to your functions to restrict their use
 * to the result of votes.
 *
 * Features:
 *
 * - allowing negative voting.
 * - linear (weighted) voting.
 *
 * References:
 *
 * - https://github.com/randao/randao
 */
contract DAO is Context {
    using SignedSafeMath for int256;

    struct Participant {
        bool voted;
    }

    struct Campaign {
        uint256 currentTime;    // [block]
        uint256 timeLimit;      // [block]
        int256[] votes;
        mapping(address => Participant) participants;
        bool ended;
        bool result;
    }

    // requestType:
    struct Request {
        bytes32 name;   // uses bytes32 instead of string for deducting gas.
        uint256 campaignNum;
        bool resolve;
    }

    // Hyperparams
    uint256 private _confirmationInterval = 12; // [block]
    uint256 private _minimumTimeLimit = 300;    // [block] // ~= 1 hours

    Campaign[] private _campaigns;
    mapping(bytes32 => Request) private _requestPool;   // Hash => Request

    event CampaignCreate(uint256 indexed campaignNum);
    event CampaignVote(address indexed who, uint256 indexed campaignNum, int256 weight);
    event CampaignResult(uint256 indexed campaignNum, bool agree);
    event RequestCreate(bytes32 indexed key, uint256 campaignNum);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (
        // ...
    ) internal {
        // ...
    }

    /**
     * @dev Sends the voting request.
     */
    function sendRequest(
        bytes32 name_,
        bytes32[] memory arguments_,
        uint256 timeLimit
    ) public virtual returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        campaignNum_ = createCampaign(timeLimit);
        bool resolve_ = false;

        key_ = keccak256(abi.encodePacked(
            name_,
            campaignNum_,   // unique
            resolve_,
            arguments_
        ));

        _requestPool[key_] = Request({
            name: name_,
            campaignNum: campaignNum_,
            resolve: resolve_
        });

        emit RequestCreate(key_, campaignNum_);
    }

    /**
     * @dev Returns voting result.
     */
    function resolveRequest(
        bytes32 name_,
        bytes32[] memory arguments_,
        bytes32 key_
    ) public virtual returns (bool) {
        Request storage request = _requestPool[key_];
        
        // conditions
        require(!request.resolve, "The request is already resolved.");
        require(request.name == name_, "The request type is not 'add'.");
        require(    // key verification
            key_ == keccak256(abi.encodePacked(
                request.name,
                request.campaignNum,
                request.resolve,
                arguments_
            )),
            "Wrong key, name or arguments."
        );

        request.resolve = true;

        return getResultAt(request.campaignNum);
    }

    /**
     * @dev Returns the confirmation intervals [block] .
     */
    function getConfirmationInterval(
        // ...
    ) public view returns (uint256) {
        return _confirmationInterval;
    }

    /**
     * @dev Requests the setting `_confirmationInterval`.
     */
    function setConfirmationIntervalRequest(
        uint256 newConfirmationInterval,
        uint256 timeLimit
    ) public virtual returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        // "setConfirmationInterval"
        bytes32 name_ = 0x736574436f6e6669726d6174696f6e496e74657276616c000000000000000000;

        bytes32[] memory arguments_;
        arguments_[0] = bytes32(newConfirmationInterval);

        return sendRequest(name_, arguments_, timeLimit);
    }

    /**
     * @dev Sets {_confirmationInterval} to a value
     * other than the default one of 12.
     *
     * Requirements:
     *
     * - the `newConfirmationInterval` < `_minimumTimeLimit`.
     *
     * References:
     *
     * https://ethereum.stackexchange.com/questions/183/203#203
     */
    function setConfirmationInterval(
        uint256 newConfirmationInterval,
        bytes32 key_
    ) public virtual returns (bool) {
        // "setConfirmationInterval"
        bytes32 name_ = 0x736574436f6e6669726d6174696f6e496e74657276616c000000000000000000;

        bytes32[] memory arguments_;
        arguments_[0] = bytes32(newConfirmationInterval);

        // conditions
        require(resolveRequest(name_, arguments_, key_));

        /* body start */
        _confirmationInterval = newConfirmationInterval;
        /* body end */

        return true;
    }

    /**
     * @dev Returns the minimum time limit [block] .
     */
    function getMinimumTimeLimit(
        // ...
    ) public view returns (uint256) {
        return _minimumTimeLimit;
    }

    /**
     * @dev Requests the setting `_minimumTimeLimit`.
     */
    function setMinimumTimeLimitRequest(
        uint256 newMinimumTimeLimit,
        uint256 timeLimit
    ) public virtual returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        // "setMinimumTimeLimit"
        bytes32 name_ = 0x7365744d696e696d756d54696d654c696d697400000000000000000000000000;

        bytes32[] memory arguments_;
        arguments_[0] = bytes32(newMinimumTimeLimit);

        return sendRequest(name_, arguments_, timeLimit);
    }

    /**
     * @dev Sets {_minimumTimeLimit} to a value
     * other than the default one of 300.
     *
     * Requirements:
     *
     * - the `newMinimumTimeLimit` > `_confirmationInterval`.
     */
    function setMinimumTimeLimit(
        uint256 newMinimumTimeLimit,
        bytes32 key_
    ) public virtual returns (bool) {
        // "setConfirmationInterval"
        bytes32 name_ = 0x7365744d696e696d756d54696d654c696d697400000000000000000000000000;

        bytes32[] memory arguments_;
        arguments_[0] = bytes32(newMinimumTimeLimit);

        // conditions
        require(resolveRequest(name_, arguments_, key_));

        /* body start */
        _minimumTimeLimit = newMinimumTimeLimit;
        /* body end */

        return true;
    }

    function createCampaign(
        uint256 timeLimit
    ) public virtual returns (
        uint256 campaignNum_
    ) {
        // conditions
        require(
            timeLimit >= _minimumTimeLimit,
            "`timeLimit` MUST be higher than or at least same as `_minimumTimeLimit`."
        );

        _campaigns.push();
        campaignNum_ = _campaigns.length - 1;
        Campaign storage campaign = _campaigns[campaignNum_];

        emit CampaignCreate(campaignNum_);

        campaign.currentTime = block.number;
        campaign.timeLimit = timeLimit;
    }

    function voteAt(
        uint256 campaignNum,
        int256 weights
    ) public virtual returns (bool) {
        Campaign storage campaign = _campaigns[campaignNum];
        address msgSender = _msgSender();
        Participant storage participant = campaign.participants[msgSender];

        // conditions
        require(!campaign.ended, "The campaign is ended.");
        require(campaign.currentTime + campaign.timeLimit > block.number, "Exceed time limit.");
        require(!participant.voted, "You already voted.");

        participant.voted = true;

        emit CampaignVote(msgSender, campaignNum, weights);

        campaign.votes.push(weights);

        return true;
    }

    /** 
     * @dev Computes and returns the result.
     */
    function getResultAt(
        uint256 campaignNum
    ) public returns (
        bool agree_
    ) {
        Campaign storage campaign = _campaigns[campaignNum];

        if (campaign.ended) {
            return campaign.result;
        }

        // conditions
        require(!campaign.ended, "Already ended.");
        require(campaign.currentTime + campaign.timeLimit <= block.number, "Not yet.");

        campaign.ended = true;

        int256 result_ = 0;
        for (uint256 i=0; i<campaign.votes.length; i++) {
            result_ = result_.add(campaign.votes[i]);
        }

        campaign.result = (result_ > 0);

        emit CampaignResult(campaignNum, campaign.result);

        return campaign.result;
    }

    // /**
    //  * @dev Converts uint256 to int256.
    //  */
    // function _uintToInt(
    //     uint256 elem
    // ) internal pure returns (
    //     int256 res_
    // ) {
    //     require(elem < uint256(-1), "Can't cast: cout of range of int256 max.");

    //     res_ = int256(elem);
    // }
}
