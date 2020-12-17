// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "../VOTEDAO.sol";
import "./IOwnable.sol";


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
contract OWNEDAO is Context, VOTEDAO, IOwnable {
    mapping(address => uint8) private _owners;

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
    ) public returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        // "addOwnership"
        bytes32 name_ = 0x6164644f776e6572736869700000000000000000000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](2);
        arguments_[0] = bytes32(bytes20(account));
        arguments_[1] = bytes32(uint256(level));

        return vSendRequest(name_, arguments_, timeLimit);
    }

    /**
     * @dev Adds the ownership.
     */
    function addOwnership(
        address account,
        uint8 level,
        bytes32 key_
    ) public returns (bool) {
        // "addOwnership"
        bytes32 name_ = 0x6164644f776e6572736869700000000000000000000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](2);
        arguments_[0] = bytes32(bytes20(account));
        arguments_[1] = bytes32(uint256(level));

        // conditions
        require(vResolveRequest(name_, arguments_, key_));

        /* body start */
        _addOwnership(account, level);
        /* body end */

        return true;
    }

    /**
     * @dev Requests the deleting ownership.
     */
    function deleteOwnershipRequest(
        address account,
        uint256 timeLimit
    ) public returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        // "deleteOwnership"
        bytes32 name_ = 0x64656c6574654f776e6572736869700000000000000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](1);
        arguments_[0] = bytes32(bytes20(account));

        return vSendRequest(name_, arguments_, timeLimit);
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
    ) public returns (bool) {
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
        bytes32 key_
    ) public returns (bool) {
        // "deleteOwnership"
        bytes32 name_ = 0x64656c6574654f776e6572736869700000000000000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](1);
        arguments_[0] = bytes32(bytes20(account));

        // conditions
        require(vResolveRequest(name_, arguments_, key_));

        /* body start */
        _deleteOwnership(account);
        /* body end */

        return true;
    }

    /**
     * @dev Requests the transfering ownership.
     */
    function transferOwnershipRequest(
        address oldOwner,
        address newOwner,
        uint256 timeLimit
    ) public returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        // "transferOwnership"
        bytes32 name_ = 0x7472616e736665724f776e657273686970000000000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](2);
        arguments_[0] = bytes32(bytes20(oldOwner));
        arguments_[1] = bytes32(bytes20(newOwner));

        return vSendRequest(name_, arguments_, timeLimit);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     *
     * Can be called by himself.
     */
    function transferOwnership(
        address newOwner
    ) public returns (bool) {
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
        bytes32 key_
    ) public returns (bool) {
        // "transferOwnership"
        bytes32 name_ = 0x7472616e736665724f776e657273686970000000000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](2);
        arguments_[0] = bytes32(bytes20(oldOwner));
        arguments_[1] = bytes32(bytes20(newOwner));

        // conditions
        require(vResolveRequest(name_, arguments_, key_));

        /* body start */
        _transferOwnership(oldOwner, newOwner);
        /* body end */

        return true;
    }

    /**
     * @dev Requests the changing ownership level.
     */
    function changeOwnershipLevelRequest(
        address account,
        uint8 level,
        uint256 timeLimit
    ) public returns (
        bytes32 key_,
        uint256 campaignNum_
    ) {
        // "changeOwnershipLevel"
        bytes32 name_ = 0x6368616e67654f776e6572736869704c6576656c000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](2);
        arguments_[0] = bytes32(bytes20(account));
        arguments_[1] = bytes32(uint256(level));

        return vSendRequest(name_, arguments_, timeLimit);
    }

    /**
     * @dev Changes ownership level.
     */
    function changeOwnershipLevel(
        address account,
        uint8 level,
        bytes32 key_
    ) public returns (bool) {
        // "changeOwnershipLevel"
        bytes32 name_ = 0x6368616e67654f776e6572736869704c6576656c000000000000000000000000;

        bytes32[] memory arguments_ = new bytes32[](2);
        arguments_[0] = bytes32(bytes20(account));
        arguments_[1] = bytes32(uint256(level));

        // conditions
        require(vResolveRequest(name_, arguments_, key_));

        /* body start */
        _changeOwnershipLevel(account, level);
        /* body end */

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
     * @dev Votes the campaign.
     */
    function voteAt(
        uint256 campaignNum,
        bool agree_
    ) public onlyOwner(1) returns (bool) {
        address msgSender = _msgSender();

        int256 weights_ = int256(levelOf(msgSender));
        if (!agree_) {
            weights_ *= (-1);
        }

        return _voteAt(campaignNum, weights_);
    }
}
