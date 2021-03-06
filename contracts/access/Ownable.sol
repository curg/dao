// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IOwnable.sol";
import "openzeppelin-solidity/contracts/GSN/Context.sol";


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
 * References:
 *
 * - openzeppelin-solidity/contracts/access/Ownable.sol
 */
contract Ownable is Context, IOwnable {
    mapping(address => uint8) private _owners;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (
        // ...
    ) internal {
        address msgSender = _msgSender();
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
     * @dev Calls {_addOwnership}.
     */
    function addOwnership(
        address account,
        uint8 level
    ) public virtual onlyOwner(255) returns (bool) {
        _addOwnership(account, level);

        return true;
    }

    /**
     * @dev Calls {_deleteOwnership}.
     */
    function deleteOwnership(
        address account
    ) public virtual onlyOwner(255) returns (bool) {
        _deleteOwnership(account);

        return true;
    }

    /**
     * @dev Calls {_transferOwnership}.
     */
    function transferOwnership(
        address oldOwner,
        address newOwner
    ) public virtual onlyOwner(255) returns (bool) {
        _transferOwnership(oldOwner, newOwner);

        return true;
    }

    /**
     * @dev Calls {_changeOwnershipLevel}.
     */
    function changeOwnershipLevel(
        address account,
        uint8 level
    ) public virtual onlyOwner(255) returns (bool) {
        _changeOwnershipLevel(account, level);

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
}
