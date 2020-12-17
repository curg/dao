// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Contract module which provides a Decentralized Autonomous
 * Organization (DAO) mechanism.
 *
 * This module is used through inheritance. It will make available the
 * function {sendRequest} and {resolveRequest}, which can be applied to
 * restrict their use.
 */
contract DAO {
    struct Request {
        bytes32 name;   // uses bytes32 instead of string for deducting gas.
        uint256 campaignNum;
        bool resolve;
    }

    // Hyperparams
    uint256 internal _confirmationInterval = 12; // [block]
    uint256 internal _minimumTimeLimit = 300;    // [block] // ~= 1 hours

    mapping(bytes32 => Request) internal _requestPool;   // Hash => Request

    event RequestCreate(bytes32 indexed key, uint256 campaignNum);

    /**
     * @dev Sends the governance request.
     *
     * It MUST be called by the public function 'sendRequest' which
     * calculates new campaign number automatically.
     */
    function _sendRequest(
        uint256 campaignNum_,
        bytes32 name_,
        bytes32[] memory arguments_
    ) internal returns (
        bytes32 key_
    ) {
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
     * @dev Resolves governance.
     *
     * It MUST be called by the public function 'resolveRequest' which
     * returns governance's result by 'getResult'.
     */
    function _resolveRequest(
        bytes32 name_,
        bytes32[] memory arguments_,
        bytes32 key_
    ) internal returns (bool) {
        Request storage request = _requestPool[key_];
        
        // conditions
        require(!request.resolve, "The request is already resolved.");
        require(request.name == name_, "The request name is wrong.");
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

        return request.resolve;
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
    function _setConfirmationInterval(
        uint256 newConfirmationInterval
    ) internal returns (bool) {
        require(newConfirmationInterval < _minimumTimeLimit);

        _confirmationInterval = newConfirmationInterval;

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
     * @dev Sets {_minimumTimeLimit} to a value
     * other than the default one of 300.
     *
     * Requirements:
     *
     * - the `newMinimumTimeLimit` > `_confirmationInterval`.
     */
    function _setMinimumTimeLimit(
        uint256 newMinimumTimeLimit
    ) internal returns (bool) {
        require(newMinimumTimeLimit > _confirmationInterval);

        _minimumTimeLimit = newMinimumTimeLimit;

        return true;
    }
}
