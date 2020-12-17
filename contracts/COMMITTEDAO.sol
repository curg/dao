// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "./DAO.sol";


/**
 * @dev Contract module which provides a Decentralized Autonomous Organization
 * (DAO) mechanism with the commitment-reveal scheme on uint256 number and
 * (weighted) anti-cheating voting system for safe governance.
 *
 * This module is used through inheritance. It will make available the function
 * {cSendRequest} and {cResolveRequest}, which can be applied to restrict their
 * use to the result of votes.
 *
 * Features:
 *
 * - allowing commitment-reveal scheme on uint256 number.
 * - the result is XORs of secret numbers.
 * - voting uncheatably.
 *
 * References:
 *
 * - https://github.com/randao/randao
 */ 
contract COMMITTEDAO is Context, DAO {
    struct CParticipant {
        bytes32 commitment;
        bool revealed;
    }

    struct CCampaign {
        uint256 currentTime;        // [block]
        uint256 commitTimeLimit;    // [block]
        uint256 revealTimeLimit;    // [block]
        uint256[] secrets;
        mapping(address => CParticipant) participants;
        bool ended;
        uint256 result;
    }

    CCampaign[] private _campaigns;

    event CCampaignCreate(uint256 indexed campaignNum);
    event CCampaignCommit(address indexed who, uint256 indexed campaignNum, bytes32 commitment);
    event CCampaignReveal(address indexed who, uint256 indexed campaignNum, uint256 secret);
    event CCampaignResult(uint256 indexed campaignNum, uint256 xored);

    // Using this as abstract contract.
    constructor (
        // ...
    ) internal {
        // ...
    }

    /**
     * @dev Sends the governance request.
     */
    function cSendRequest(
        bytes32 name_,
        bytes32[] memory arguments_,
        uint256 commitTimeLimit_,
        uint256 revealTimeLimit_
    ) public returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        campaignNum_ = cCreateCampaign(commitTimeLimit_, revealTimeLimit_);
        key_ = _sendRequest(campaignNum_, name_, arguments_);
    }

    /**
     * @dev Returns XOR-ed result.
     */
    function cResolveRequest(
        bytes32 name_,
        bytes32[] memory arguments_,
        bytes32 key_
    ) public returns (uint256) {
        bool resolve_ = _resolveRequest(name_, arguments_, key_);
        require(resolve_, "The request cannot be resolved.");

        Request storage request = _requestPool[key_];
        return cGetResultAt(request.campaignNum);
    }

    /**
     * @dev Creates the campaign.
     *
     * Total time limit is `commitTimeLimit_` + `revealTimeLimit_`.
     */
    function cCreateCampaign(
        uint256 commitTimeLimit_,
        uint256 revealTimeLimit_
    ) public returns (
        uint256 campaignNum_
    ) {
        // conditions
        require(
            commitTimeLimit_ >= _minimumTimeLimit,
            "`commitTimeLimit_` MUST be higher than or at least same as `_minimumTimeLimit`."
        );
        require(
            revealTimeLimit_ >= _minimumTimeLimit,
            "`revealTimeLimit_` MUST be higher than or at least same as `_minimumTimeLimit`."
        );

        _campaigns.push();
        campaignNum_ = _campaigns.length - 1;
        CCampaign storage campaign = _campaigns[campaignNum_];

        emit CCampaignCreate(campaignNum_);

        campaign.currentTime = block.number;
        campaign.commitTimeLimit = commitTimeLimit_;
        campaign.revealTimeLimit = revealTimeLimit_;
    }

    /**
     * @dev Commits hidden number at the campaign.
     *
     * It MUST be called by the public function 'commitAt'.
     */
    function _commitAt(
        uint256 campaignNum,
        bytes32 commitment_
    ) internal returns (bool) {
        CCampaign storage campaign = _campaigns[campaignNum];
        address msgSender = _msgSender();
        CParticipant storage participant = campaign.participants[msgSender];

        // conditions
        require(commitment_ != bytes32(0), "The commitment cannot be zero.");
        require(!campaign.ended, "The campaign is ended.");
        require(
            campaign.currentTime + campaign.commitTimeLimit > block.number,
            "Exceed time limit."
        );
        require(participant.commitment == bytes32(0), "You already joined before.");

        participant.commitment = commitment_;

        emit CCampaignCommit(msgSender, campaignNum, commitment_);

        return true;
    }

    /**
     * @dev Makes hidden number public with `secret_` and `seed_`.
     *
     * It MUST be called by the public function 'revealAt'.
     */
    function _revealAt(
        uint256 campaignNum,
        uint256 secret_,
        uint256 seed_
    ) internal returns (bool) {
        CCampaign storage campaign = _campaigns[campaignNum];
        address msgSender = _msgSender();
        CParticipant storage participant = campaign.participants[msgSender];

        // conditions
        require(
            participant.commitment != bytes32(0),
            "You've not joined commitment-phase before."
        );
        require(!campaign.ended, "The campaign is ended.");
        require(
            campaign.currentTime + campaign.commitTimeLimit <= block.number,
            "Not yet."
        );
        uint256 timeLimit = campaign.commitTimeLimit + campaign.revealTimeLimit;
        require(
            campaign.currentTime + timeLimit > block.number, 
            "Exceed time limit."
        );
        require(!participant.revealed, "You already revealed the commitment before.");
        require(
            participant.commitment == keccak256(abi.encodePacked(secret_, seed)),
            "Wrong secret and seed."
        );

        campaign.secrets.push(secret_);

        emit CCampaignReveal(msgSender, campaignNum, secret);

        return true;
    }

    /** 
     * @dev Computes XOR and saves the result at the `campaignNum`-th campaign.
     */
    function cGetResultAt(
        uint256 campaignNum
    ) public returns (
        uint256 xored_
    ) {
        CCampaign storage campaign = _campaigns[campaignNum];

        if (campaign.ended) {
            return campaign.result;
        }

        // conditions
        require(!campaign.ended, "Already ended.");
        uint256 timeLimit = campaign.commitTimeLimit + campaign.revealTimeLimit;
        require(
            campaign.currentTime + timeLimit <= block.number,
            "Not yet."
        );

        campaign.ended = true;

        for (uint256 i=0; i<campaign.secrets.length; i++) {
            xored_ ^= campaign.secrets[i];
        }

        campaign.result = xored_;

        emit CCampaignResult(campaignNum, xored_);

        return campaign.result;
    }

    /**
     * @dev Returns voting result.
     *
     * You can use `CCampaign` for voting purpose like 'VCampaign' in 'VOTEDAO'
     * but uncheatable.
     */
    function cResolveVoteRequest(
        bytes32 name_,
        bytes32[] memory arguments_,
        bytes32 key_
    ) public returns (bool) {
        bool resolve_ = _resolveRequest(name_, arguments_, key_);
        require(resolve_, "The request cannot be resolved.");

        Request storage request = _requestPool[key_];
        return cGetVoteResultAt(request.campaignNum);
    }

    /**
     * @dev Votes the campaign.
     *
     * It MUST be called by the public function 'hiddenVoteAt'.
     */
    function _hiddenVoteAt(
        uint256 campaignNum,
        bytes32 commitment_
    ) internal returns (bool) {
        return _commitAt(campaignNum, commitment_);
    }

    /**
     * @dev Reveals vote.
     *
     * `weights` is saved as uint256 number in CCampaign, but you are still able
     * to express minus number. For example, '-1' is int256(11579208923731619542
     * 3570985008687907853269984665640564039457584007913129639935) .
     *
     * It MUST be called by the public function 'revealVoteAt'.
     */
    function _revealVoteAt(
        uint256 campaignNum,
        int256 weights, // secret
        uint256 seed_
    ) internal returns (bool) {
        return _revealAt(campaignNum, uint256(weights), seed_);
    }

    /** 
     * @dev Computes and saves the result at the `campaignNum`-th campaign.
     */
    function cGetVoteResultAt(
        uint256 campaignNum
    ) public returns (bool) {
        CCampaign storage campaign = _campaigns[campaignNum];

        if (campaign.ended) {
            return campaign.result;
        }

        // conditions
        require(!campaign.ended, "Already ended.");
        uint256 timeLimit = campaign.commitTimeLimit + campaign.revealTimeLimit;
        require(
            campaign.currentTime + timeLimit <= block.number,
            "Not yet."
        );

        campaign.ended = true;

        int256 result_ = 0;
        for (uint256 i=0; i<campaign.secrets.length; i++) {
            // type conversion
            result_ = result_.add(int256(campaign.secrets[i]));
        }

        // 1 for true
        // 0 for false
        campaign.result = (result_ > 0) ? 1 : 0;

        emit CCampaignResult(campaignNum, campaign.result);

        return (result_ > 0);
    }

    /**
     * @dev Requests the setting `_confirmationInterval`.
     */
    function setConfirmationIntervalRequest(
        uint256 newConfirmationInterval,
        uint256 commitTimeLimit_,
        uint256 revealTimeLimit_
    ) public virtual returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        // "setConfirmationInterval"
        bytes32 name_ = 0x736574436f6e6669726d6174696f6e496e74657276616c000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](1);
        arguments_[0] = bytes32(newConfirmationInterval);

        return cSendRequest(name_, arguments_, commitTimeLimit_, revealTimeLimit_);
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
        require(cResolveVoteRequest(name_, arguments_, key_));

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
        uint256 commitTimeLimit_,
        uint256 revealTimeLimit_
    ) public virtual returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        // "setMinimumTimeLimit"
        bytes32 name_ = 0x7365744d696e696d756d54696d654c696d697400000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](1);
        arguments_[0] = bytes32(newMinimumTimeLimit);

        return cSendRequest(name_, arguments_, commitTimeLimit_, revealTimeLimit_);
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
        require(cResolveVoteRequest(name_, arguments_, key_));

        /* body start */
        _setMinimumTimeLimit(newMinimumTimeLimit);
        /* body end */

        return true;
    }
}
