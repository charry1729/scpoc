// SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.7.3/security/Pausable.sol";
import "@openzeppelin/contracts@4.7.3/access/AccessControl.sol";

contract Supplychain is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    bytes32 public constant SUPPLIER_ROLE = keccak256("SUPPLIER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MANUFACTURER_ROLE, msg.sender);
        _grantRole(SUPPLIER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    struct assetDetail {
        bytes32 assetNum;
        string assetName;
        string currentowner;
        string previousowner;
        string ipfsURL;
        status txnstatus;
    }
    enum status {
        newasset,
        ownerchanged,
        assettransferred
    }
    event CreateAsset(
        bytes32 _assetNum,
        string _assetName,
        string _currentowner,
        string _previousowner,
        string _ipfsURL,
        status txnstatus
    );
    event Changeowner(
        string _previousowner,
        string _currentowner,
        status _txnstatus
    );

    mapping(bytes32 => assetDetail) aDetails;

    function createAsset(
        bytes32 _assetNum,
        string memory _assetName,
        string memory _currentowner,
        string memory _previousowner,
        string memory _ipfsURL,
        status txnstatus
    ) public onlyRole(MANUFACTURER_ROLE) returns (bytes32, status) {
        aDetails[_assetNum].assetNum = _assetNum;
        aDetails[_assetNum].assetName = _assetName;
        aDetails[_assetNum].currentowner = _currentowner;
        aDetails[_assetNum].previousowner = _previousowner;
        aDetails[_assetNum].ipfsURL = _ipfsURL;
        status statuses = status.newasset;
        aDetails[_assetNum].txnstatus = status.newasset;

        emit CreateAsset(
            _assetNum,
            _assetName,
            _currentowner,
            _previousowner,
            _ipfsURL,
            txnstatus
        );
        // CreateAsset1(_assetNum,_currentowner,_previousowner);
        // CreateAsset2(_assetNum,_assetName,_ipfsURL);

        return (_assetNum, statuses);
    }

    function traceAssetDetails(bytes32 assetNum)
        public
        view
        returns (
            bytes32 _assetNum,
            string memory _assetName,
            string memory _currentowner,
            string memory _previousowner,
            string memory _ipfsURL,
            status txnstatus
        )
    {
        return (
            aDetails[assetNum].assetNum,
            aDetails[assetNum].assetName,
            aDetails[assetNum].currentowner,
            aDetails[assetNum].previousowner,
            aDetails[assetNum].ipfsURL,
            aDetails[assetNum].txnstatus
        );
    }

    function tradeAsset(bytes32 _assetNum, string memory _newowner)
        public
        onlyRole(SUPPLIER_ROLE)
        returns (
            string memory previousowner,
            string memory currentowner,
            status txnstatus
        )
    {
        require(aDetails[_assetNum].txnstatus == status.newasset);

        aDetails[_assetNum].previousowner = aDetails[_assetNum].currentowner;
        aDetails[_assetNum].currentowner = _newowner;
        aDetails[_assetNum].txnstatus = status.ownerchanged;
        emit Changeowner(
            aDetails[_assetNum].previousowner,
            aDetails[_assetNum].currentowner,
            aDetails[_assetNum].txnstatus
        );
        return (
            aDetails[_assetNum].previousowner,
            aDetails[_assetNum].currentowner,
            aDetails[_assetNum].txnstatus
        );
    }
}

contract Lock {
    uint256 public unlockTime;
    address payable public owner;

    event Withdrawal(uint256 amount, uint256 when);

    constructor(uint256 _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function withdraw() public {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}
