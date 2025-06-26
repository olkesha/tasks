// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DataLogic {
    struct User {
        string name;
        uint256 age;
        bool registered;
    }
    mapping(address => User) public users;

    address public addressOfDataManager;

    event UserDataSet(string, uint256, bool);
    event UserDataCleared(User);
    event NewDataManagerSet(address);
    event initializationSuccessed();

    function setUserData(address _address, string memory _name, uint256 _age) external {
        users[_address] = User({name: _name, age: _age, registered: true});

        emit UserDataSet(_name, _age, users[_address].registered);
    }

    function clearUserData(address _address) external {
        delete users[_address];

        emit UserDataCleared(users[_address]);
    }

    function setNewDataManager(address _address) external {
        addressOfDataManager = _address;

        emit NewDataManagerSet(_address);
    }

    // function getUserData(address _address) external view returns(User memory) {
    //     return users[_address];
    // }

    function initialize(address _address) external {
        addressOfDataManager = _address;

        emit initializationSuccessed();
    }
}

contract DataManager {
    struct User {
        string name;
        uint256 age;
        bool registered;
    }
    mapping(address => User) public users;

    address public dataLogic;

    error FailedToReceiveData();

    constructor(address _dataLogicContract) {
        dataLogic = _dataLogicContract;
        (bool success, ) = dataLogic.call(abi.encodeWithSignature("initialize(address)", address(this)));
    }

    function setUserData(address _address, string memory _name, uint256 _age) external {
        (bool success, ) = dataLogic.delegatecall(
            abi.encodeWithSignature("setUserData(address,string,uint256)", 
            _address, _name, _age)
        );

        require(success, FailedToReceiveData());
    }

    function clearUserData(address _address) external {
        (bool success, ) = dataLogic.delegatecall(
            abi.encodeWithSignature("clearUserData(address)", _address)
        );

        require(success, FailedToReceiveData());
    }

    function setNewDataManager(address _address) external {
        (bool success, ) = dataLogic.call(abi.encodeWithSignature("setNewDataManager(address)", _address));

        require(success, FailedToReceiveData());
    }

    // function getUserData(address _address) external returns(User memory userData) {
    //     (bool success, bytes memory data) = dataLogic.call(abi.encodeWithSignature("getUserData(address)", _address));

    //     require(success, FailedToReceiveData());
    //     userData = abi.decode(data, (User));
    // }

    function getUserDataFromDataManager(address _address) public view returns(User memory) {
        return users[_address];
    }

    function setNewDataLogic(address _newDataLogic) public {
        dataLogic = _newDataLogic;
    }
}
