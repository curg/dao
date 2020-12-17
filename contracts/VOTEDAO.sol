// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "./DAO.sol";
import "openzeppelin-solidity/contracts/math/SignedSafeMath.sol";


/**
 * @dev Contract module which provides a Decentralized Autonomous Organization
 * (DAO) mechanism, where including the (weighted) voting system for governance.
 *
 * This module is used through inheritance. It will make available the function
 * {vSendRequest} and {vResolveRequest}, which can be applied to restrict their use
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
contract VOTEDAO is Context, DAO {
    using SignedSafeMath for int256;

    struct VParticipant {
        bool voted;
    }

    struct VCampaign {
        uint256 currentTime;    // [block]
        uint256 timeLimit;      // [block]
        int256[] votes;
        mapping(address => VParticipant) participants;
        bool ended;
        bool result;
    }

    VCampaign[] private _campaigns;

    event VCampaignCreate(uint256 indexed campaignNum);
    event VCampaignVote(address indexed who, uint256 indexed campaignNum, int256 weight);
    event VCampaignResult(uint256 indexed campaignNum, bool agree);

    // Using this as abstract contract.
    constructor (
        // ...
    ) internal {
        // ...
    }

    /**
     * @dev Sends the governance request.
     */
    function vSendRequest(
        bytes32 name_,
        bytes32[] memory arguments_,
        uint256 timeLimit_
    ) public returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        campaignNum_ = vCreateCampaign(timeLimit_);
        key_ = _sendRequest(campaignNum_, name_, arguments_);
    }

    /**
     * @dev Returns voting result.
     */
    function vResolveRequest(
        bytes32 name_,
        bytes32[] memory arguments_,
        bytes32 key_
    ) public returns (bool) {
        bool resolve_ = _resolveRequest(name_, arguments_, key_);
        require(resolve_, "The request cannot be resolved.");

        Request storage request = _requestPool[key_];
        return vGetResultAt(request.campaignNum);
    }

    /**
     * @dev Creates the campaign.
     */
    function vCreateCampaign(
        uint256 timeLimit_
    ) public returns (
        uint256 campaignNum_
    ) {
        // conditions
        require(
            timeLimit_ >= _minimumTimeLimit,
            "`timeLimit_` MUST be higher than or at least same as `_minimumTimeLimit`."
        );

        _campaigns.push();
        campaignNum_ = _campaigns.length - 1;
        VCampaign storage campaign = _campaigns[campaignNum_];

        emit VCampaignCreate(campaignNum_);

        campaign.currentTime = block.number;
        campaign.timeLimit = timeLimit_;
    }

    /**
     * @dev Votes the campaign.
     *
     * It MUST be called by the public function 'voteAt'.
     */
    function _voteAt(
        uint256 campaignNum,
        int256 weights
    ) internal returns (bool) {
        VCampaign storage campaign = _campaigns[campaignNum];
        address msgSender = _msgSender();
        VParticipant storage participant = campaign.participants[msgSender];

        // conditions
        require(!campaign.ended, "The campaign is ended.");
        require(campaign.currentTime + campaign.timeLimit > block.number, "Exceed time limit.");
        require(!participant.voted, "You already voted.");

        participant.voted = true;

        emit VCampaignVote(msgSender, campaignNum, weights);

        campaign.votes.push(weights);

        return true;
    }

    /** 
     * @dev Computes and saves the result at the `campaignNum`-th campaign.
     */
    function vGetResultAt(
        uint256 campaignNum
    ) public returns (bool) {
        VCampaign storage campaign = _campaigns[campaignNum];

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

        emit VCampaignResult(campaignNum, campaign.result);

        return (result_ > 0);
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

        bytes32[] memory arguments_ = new bytes32[](1);
        arguments_[0] = bytes32(newConfirmationInterval);

        return vSendRequest(name_, arguments_, timeLimit);
    }

    /**
     * @dev Calls {_setConfirmationInterval}.
     */
    function setConfirmationInterval(
        uint256 newConfirmationInterval,
        bytes32 key_
    ) public virtual returns (bool) {
        // "setConfirmationInterval"
        bytes32 name_ = 0x736574436f6e6669726d6174696f6e496e74657276616c000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](1);
        arguments_[0] = bytes32(newConfirmationInterval);

        // conditions
        require(vResolveRequest(name_, arguments_, key_));

        /* body start */
        _setConfirmationInterval(newConfirmationInterval);
        /* body end */

        return true;
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

        bytes32[] memory arguments_ = new bytes32[](1);
        arguments_[0] = bytes32(newMinimumTimeLimit);

        return vSendRequest(name_, arguments_, timeLimit);
    }

    /**
     * @dev Calls {_setMinimumTimeLimit}.
     */
    function setMinimumTimeLimit(
        uint256 newMinimumTimeLimit,
        bytes32 key_
    ) public virtual returns (bool) {
        // "setConfirmationInterval"
        bytes32 name_ = 0x7365744d696e696d756d54696d654c696d697400000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](1);
        arguments_[0] = bytes32(newMinimumTimeLimit);

        // conditions
        require(vResolveRequest(name_, arguments_, key_));

        /* body start */
        _setMinimumTimeLimit(newMinimumTimeLimit);
        /* body end */

        return true;
    }
}
