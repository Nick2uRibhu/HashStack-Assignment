//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AccessRegistry {

    //Events
    event AddSignatory(address indexed signatory, string message);
    event RevokeSignatory(address indexed signatory, string message);
    event RenounceSignatory(address indexed signatory, string message);
    event TransferAdmin(address indexed admin, address indexed newAdmin, string message);

    address public admin;
    address[] private signatories;
    mapping(address => bool) private signatoriesMapping;
    mapping(address => uint) private signatoriesIndex;
    
    
    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can perform this action!");
        _;
    }

    function addSignatory(address _signatory) public onlyAdmin {
        require(!signatoriesMapping[_signatory], "This Signator already exists");
        signatoriesIndex[_signatory] = signatories.length;
        signatories.push(_signatory);
        signatoriesMapping[_signatory] = true;
        emit AddSignatory(_signatory, "Signatory added successfully");
    }

    function revokeSignatory(address _signatory) public onlyAdmin {
        require(signatoriesMapping[_signatory], "Given address is not a signator");

        _burn(signatoriesIndex[_signatory]);

        signatoriesMapping[_signatory] = false;
        emit RevokeSignatory(_signatory, "Signatory revoked successfully");
    }

    function renounceSignatory() public {
        require(signatoriesMapping[msg.sender], "Only signatories can renounce their role");
        _burn(signatoriesIndex[msg.sender]);
        signatoriesMapping[msg.sender] = false;
        emit RenounceSignatory(msg.sender, "Signatory renounced successfully");
    }

    function transferAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != admin, "Given address is already the Admin");
        require(signatoriesMapping[_newAdmin], "The new Admin must be a signatory");
        admin = _newAdmin;
        emit TransferAdmin(msg.sender, _newAdmin, "Admin transferred successfully");
    }

    function _burn(uint256 i) internal {
        require(i < signatories.length, "Invalid Index");
        signatories[i] = signatories[signatories.length - 1];
        signatories.pop();
    }

    function getSignatories() public view returns (address[] memory) {
        return signatories;
    }

    function isSignatory(address _signatory) external view returns (bool) {
        return signatoriesMapping[_signatory];
    }
}