//SPDX-License-Identifier: MIT

//Interface of the AccessRegistry Smart Contract
interface AccessRegistryInterface {
    function isSignatory(address _signatory) external view returns (bool);
    function getSignatories() external view returns (address[] memory);
}

pragma solidity ^0.8.0;

contract MultiSigWallet {

    //Events
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(bytes32 indexed hash, address indexed owner, address indexed to, uint value);
    event ConfirmTransaction(address indexed signator, bytes32 indexed hash, uint numOfConfirmation);
    event ExecuteTransaction(string message);

    //Address of the Accessegistry Smart Contract
    address private accessRegistryAddress;

    //Structure of the Transaction
    struct Transaction {
        address payable to;
        uint value;
        bool executed;
        uint numOfConfirmation;
        mapping(address => bool) confirmation;
    }

    //A mapping to store transactions with the hash as the key
    mapping(bytes32 => Transaction) public transactions;

    //It is a mapping to validate if the transaction has been submitted or not
    mapping(bytes32 => bool) private hashMapping;
    
    //Constructor to store the address of the AccessRegistry Smart Contract
    constructor(address _accessRegistryAddress) {
        accessRegistryAddress = _accessRegistryAddress;
    }

    modifier onlySignatories() {
        require(AccessRegistryInterface(accessRegistryAddress).isSignatory(msg.sender), "Only Signatories can perform this action");
        _;
    }

    //Function to receive Ethers
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    //Function to get the required signatures
    function requiredSignatures() public view returns (uint256) {
        return ((AccessRegistryInterface(accessRegistryAddress).getSignatories().length) * 60) / 100;
    }

    //Function for Submitting Transaction
    function submitTransaction(bytes32 _hash, address payable _to, uint256 _value) public onlySignatories {
        Transaction storage newTransaction = transactions[_hash];
        newTransaction.to = _to;
        newTransaction.value = _value * 10**18;
        newTransaction.executed = false;
        hashMapping[_hash] = true;
        emit SubmitTransaction(_hash, msg.sender, _to, _value);
    }

    //Function for Confirming Transaction
    function confirmTransaction(bytes32 _hash) public onlySignatories {
        require(hashMapping[_hash], "No such transactions submitted");
        Transaction storage txn = transactions[_hash];
        require(!txn.confirmation[msg.sender], "You already confirmed the transaction");
        txn.confirmation[msg.sender] = true;
        txn.numOfConfirmation++;

        if(txn.numOfConfirmation >= requiredSignatures()) {
            executeTransaction(_hash);
        }

        emit ConfirmTransaction(msg.sender, _hash, txn.numOfConfirmation);
    }

    //Internal function to execute transaction
    function executeTransaction(bytes32 _hash) internal {
        Transaction storage txn = transactions[_hash];
        require(!txn.executed, "Transaction has already been executed");
        require(address(this).balance > txn.value, "Insufficient Balance");
        txn.executed = true;
        txn.to.transfer(txn.value);
        emit ExecuteTransaction("Transaction Executed");
    }
}