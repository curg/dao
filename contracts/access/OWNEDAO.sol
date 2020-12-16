// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IOwnable.sol";
import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "openzeppelin-solidity/contracts/math/SignedSafeMath.sol";


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are accounts (owners group) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract.
 * This can later be changed with {transferOwnership} and {addOwnership} or
 * {deleteOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner(n)`, which can be applied to your functions to restrict their use
 * to the owner and owner's access level.
 *
 * There are multiple levels (0~) and the higher level takes more accessability.
 * Zero means no accessability.
 *
 * {transferOwnership} can be called by only himself, but {addOwnership} and
 * {deleteOwnership} can be called by the others. If so, level-weighted voting
 * is started to decide the action.
 *
 * References:
 *
 * - openzeppelin-solidity/contracts/access/Ownable.sol
 */
contract OWNEDAO is Context, IOwnable {
    using SignedSafeMath for int256;

    struct Participant {
        bool voted;
    }

    struct Campaign {
        uint256 currentTime;
        uint256 timeLimit;
        int256[] votes;
        mapping(address => Participant) participants;
        bool ended;
        bool result;
    }

    // requestType:
    // - 0 for 'add'
    // - 1 for 'delete'
    // - 2 for 'transfer'
    // - 3 for 'change level'
    // - 4 for 'set _confirmationInterval'
    // - 5 for 'set _minimumTimeLimit'
    struct Request {
        uint8 requestType;
        uint256 campaignNum;
        bool resolve;
    }

    // Hyperparams
    uint256 private _confirmationInterval = 12; // [block]
    uint256 private _minimumTimeLimit = 300;    // [block] // ~= 1 hours

    mapping(address => uint8) private _owners;

    Campaign[] private _campaigns;
    mapping (bytes32 => Request) private _requestPool;  // Hash => Request

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
        address msgSender = _msgSender();

        // TODO: MUST require some deposit to enter DAO.
        uint8 level = uint8(-1); // Max level
        _owners[msgSender] = level;

        emit OwnershipTransferred(address(0), msgSender, level);
    }

    /**
     * @dev Returns the level of the owner.
     */
    function levelOf(
        address owner
    ) public view override returns (uint8) {
        return _owners[owner];
    }

    /**
     * @dev Returns the level of the owner.
     */
    function isValid(
        address owner,
        uint8 level
    ) public view override returns (bool) {
        return _owners[owner] >= level;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner(
        uint8 level
    ) override {
        require(_owners[_msgSender()] >= level, "Ownable: caller has no accessability.");
        _;
    }

    /**
     * @dev Requests the adding ownership.
     */
    function addOwnershipRequest(
        address account,
        uint8 level,
        uint256 timeLimit
    ) public virtual returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        uint8 requestType_ = 0;
        campaignNum_ = createCampaign(timeLimit);
        bool resolve_ = false;

        key_ = keccak256(abi.encodePacked(
            requestType_,
            campaignNum_,   // unique
            resolve_,
            account,        // arguments
            level           // arguments
        ));

        _requestPool[key_] = Request({
            requestType: requestType_,
            campaignNum: campaignNum_,
            resolve: resolve_
        });

        emit RequestCreate(key_, campaignNum_);
    }

    /**
     * @dev Adds the ownership.
     */
    function addOwnership(
        address account,
        uint8 level,
        bytes32 key
    ) public virtual returns (bool) {
        Request storage request = _requestPool[key];
        
        // conditions
        require(!request.resolve, "The request is already resolved.");
        require(request.requestType == 0, "The request type is not 'add'.");
        require(    // key verification
            key == keccak256(abi.encodePacked(
                request.requestType,
                request.campaignNum,
                request.resolve,
                account,
                level
            )),
            "Wrong key or arguments."
        );

        request.resolve = true;

        if (getResultAt(request.campaignNum)) {
            _addOwnership(account, level);
        }

        return true;
    }

    /**
     * @dev Requests the deleting ownership.
     */
    function deleteOwnershipRequest(
        address account,
        uint256 timeLimit
    ) public virtual returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        uint8 requestType_ = 1;
        campaignNum_ = createCampaign(timeLimit);
        bool resolve_ = false;

        key_ = keccak256(abi.encodePacked(
            requestType_,
            campaignNum_,   // unique
            resolve_,
            account         // arguments
        ));

        _requestPool[key_] = Request({
            requestType: requestType_,
            campaignNum: campaignNum_,
            resolve: resolve_
        });

        emit RequestCreate(key_, campaignNum_);
    }

    /**
     * @dev Leaves the contract. It will not be possible to call `onlyOwner`
     * functions anymore if there are no other owners.
     *
     * Can be called by himself.
     *
     * NOTE: Renouncing ownership can cause removing any functionality that
     * is only available to the owners.
     */
    function deleteOwnership(
        // ...
    ) public virtual returns (bool) {
        address msgSender = _msgSender();

        _deleteOwnership(msgSender);
    
        return true;
    }

    /**
     * @dev Leaves the contract. It will not be possible to call `onlyOwner`
     * functions anymore if there are no other owners.
     *
     * Can be called by the other. It needs others' agreements.
     *
     * NOTE: Renouncing ownership can cause removing any functionality that
     * is only available to the owners.
     */
    function deleteOwnership(
        address account,
        bytes32 key
    ) public virtual returns (bool) {
        Request storage request = _requestPool[key];
        
        // conditions
        require(!request.resolve, "The request is already resolved.");
        require(request.requestType == 1, "The request type is not 'delete'.");
        require(    // key verification
            key == keccak256(abi.encodePacked(
                request.requestType,
                request.campaignNum,
                request.resolve,
                account
            )),
            "Wrong key or arguments."
        );

        request.resolve = true;

        if (getResultAt(request.campaignNum)) {
            _deleteOwnership(account);
        }

        return true;
    }

    /**
     * @dev Requests the transfering ownership.
     */
    function transferOwnershipRequest(
        address oldOwner,
        address newOwner,
        uint256 timeLimit
    ) public virtual returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        uint8 requestType_ = 2;
        campaignNum_ = createCampaign(timeLimit);
        bool resolve_ = false;

        key_ = keccak256(abi.encodePacked(
            requestType_,
            campaignNum_,   // unique
            resolve_,
            oldOwner,       // arguments
            newOwner        // arguments
        ));

        _requestPool[key_] = Request({
            requestType: requestType_,
            campaignNum: campaignNum_,
            resolve: resolve_
        });

        emit RequestCreate(key_, campaignNum_);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     *
     * Can be called by himself.
     */
    function transferOwnership(
        address newOwner
    ) public virtual returns (bool) {
        address msgSender = _msgSender();

        _transferOwnership(msgSender, newOwner);

        return true;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     *
     * Can be called by the other. It needs others' agreements.
     */
    function transferOwnership(
        address oldOwner,
        address newOwner,
        bytes32 key
    ) public virtual returns (bool) {
        Request storage request = _requestPool[key];
        
        // conditions
        require(!request.resolve, "The request is already resolved.");
        require(request.requestType == 2, "The request type is not 'transfer'.");
        require(    // key verification
            key == keccak256(abi.encodePacked(
                request.requestType,
                request.campaignNum,
                request.resolve,
                oldOwner,
                newOwner
            )),
            "Wrong key or arguments."
        );

        request.resolve = true;

        if (getResultAt(request.campaignNum)) {
            _transferOwnership(oldOwner, newOwner);
        }

        return true;
    }

    /**
     * @dev Requests the changing ownership level.
     */
    function changeOwnershipLevelRequest(
        address account,
        uint8 level,
        uint256 timeLimit
    ) public virtual returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        uint8 requestType_ = 3;
        campaignNum_ = createCampaign(timeLimit);
        bool resolve_ = false;

        key_ = keccak256(abi.encodePacked(
            requestType_,
            campaignNum_,   // unique
            resolve_,
            account,        // arguments
            level           // arguments
        ));

        _requestPool[key_] = Request({
            requestType: requestType_,
            campaignNum: campaignNum_,
            resolve: resolve_
        });

        emit RequestCreate(key_, campaignNum_);
    }

    /**
     * @dev Changes ownership level.
     */
    function changeOwnershipLevel(
        address account,
        uint8 level,
        bytes32 key
    ) public virtual returns (bool) {
        Request storage request = _requestPool[key];
        
        // conditions
        require(!request.resolve, "The request is already resolved.");
        require(request.requestType == 3, "The request type is not 'change'.");
        require(    // key verification
            key == keccak256(abi.encodePacked(
                request.requestType,
                request.campaignNum,
                request.resolve,
                account,
                level
            )),
            "Wrong key or arguments."
        );

        request.resolve = true;

        if (getResultAt(request.campaignNum)) {
            _changeOwnershipLevel(account, level);
        }

        return true;
    }

    /**
     * @dev Adds the ownership.
     */
    function _addOwnership(
        address account,
        uint8 level
    ) internal {
        require(account != address(0), "Ownable: new owner is the zero address.");
        require(_owners[account] == 0, "Ownable: ownership already exists.");

        emit OwnershipTransferred(address(0), account, level);
        
        _owners[account] = level;
    }

    /**
     * @dev Leaves the contract. It will not be possible to call `onlyOwner`
     * functions anymore if there are no other owners.
     *
     * NOTE: Renouncing ownership can cause removing any functionality that
     * is only available to the owners.
     */
    function _deleteOwnership(
        address account
    ) internal {
        require(_owners[account] != 0, "Ownable: there is no ownership.");

        emit OwnershipTransferred(account, address(0), 0);

        _owners[account] = 0;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(
        address oldOwner,
        address newOwner
    ) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");

        emit OwnershipTransferred(oldOwner, newOwner, _owners[oldOwner]);

        _owners[newOwner] = _owners[oldOwner];
        _owners[oldOwner] = 0;
    }

    /**
     * @dev Changes ownership level.
     */
    function _changeOwnershipLevel(
        address account,
        uint8 level
    ) internal {
        require(account != address(0), "Ownable: cannot change the ownership of zero address.");
        require(_owners[account] != 0, "Ownable: there is no ownership.");

        emit OwnershipTransferred(account, account, level);

        _owners[account] = level;
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
        uint8 requestType_ = 4;
        campaignNum_ = createCampaign(timeLimit);
        bool resolve_ = false;

        key_ = keccak256(abi.encodePacked(
            requestType_,
            campaignNum_,           // unique
            resolve_,
            newConfirmationInterval // arguments
        ));

        _requestPool[key_] = Request({
            requestType: requestType_,
            campaignNum: campaignNum_,
            resolve: resolve_
        });

        emit RequestCreate(key_, campaignNum_);
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
        bytes32 key
    ) public virtual returns (bool) {
        // conditions
        require(newConfirmationInterval < _minimumTimeLimit);
        Request storage request = _requestPool[key];
        require(!request.resolve, "The request is already resolved.");
        require(request.requestType == 4, "The request type is not 'set _confirmationInterval'.");
        require(    // key verification
            key == keccak256(abi.encodePacked(
                request.requestType,
                request.campaignNum,
                request.resolve,
                newConfirmationInterval
            )),
            "Wrong key or arguments."
        );

        request.resolve = true;

        if (getResultAt(request.campaignNum)) {
            _confirmationInterval = newConfirmationInterval;
        }

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
        uint8 requestType_ = 5;
        campaignNum_ = createCampaign(timeLimit);
        bool resolve_ = false;

        key_ = keccak256(abi.encodePacked(
            requestType_,
            campaignNum_,       // unique
            resolve_,
            newMinimumTimeLimit // arguments
        ));

        _requestPool[key_] = Request({
            requestType: requestType_,
            campaignNum: campaignNum_,
            resolve: resolve_
        });

        emit RequestCreate(key_, campaignNum_);
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
        bytes32 key
    ) public virtual returns (bool) {
        // conditions
        require(newMinimumTimeLimit > _confirmationInterval);
        Request storage request = _requestPool[key];
        require(!request.resolve, "The request is already resolved.");
        require(request.requestType == 5, "The request type is not 'set _minimumTimeLimit'.");
        require(    // key verification
            key == keccak256(abi.encodePacked(
                request.requestType,
                request.campaignNum,
                request.resolve,
                newMinimumTimeLimit
            )),
            "Wrong key or arguments."
        );

        request.resolve = true;

        if (getResultAt(request.campaignNum)) {
            _minimumTimeLimit = newMinimumTimeLimit;
        }

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
        bool agree_
    ) public virtual onlyOwner(1) returns (bool) {
        Campaign storage campaign = _campaigns[campaignNum];
        address msgSender = _msgSender();
        Participant storage participant = campaign.participants[msgSender];

        // conditions
        require(!campaign.ended, "The campaign is ended.");
        require(campaign.currentTime + campaign.timeLimit > block.number, "Exceed time limit.");
        require(!participant.voted, "You already voted.");

        participant.voted = true;

        // int256 weightedAgree = _uintToInt(_pow(2, levelOf(msgSender)));
        int256 weightedAgree = _uintToInt(levelOf(msgSender));
        if (!agree_) {
            weightedAgree *= (-1);
        }

        emit CampaignVote(msgSender, campaignNum, weightedAgree);

        campaign.votes.push(weightedAgree);

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

    /**
     * @dev Converts uint256 to int256.
     */
    function _uintToInt(
        uint256 elem
    ) internal pure returns (
        int256 res_
    ) {
        require(elem < uint256(-1), "Can't cast: cout of range of int256 max.");

        res_ = int256(elem);
    }
}
