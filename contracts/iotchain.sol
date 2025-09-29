// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IoTChain
 * @dev A decentralized IoT device management and data verification system
 * @author IoTChain Team
 */
contract IoTChain {
    
    struct IoTDevice {
        address owner;
        string deviceId;
        string deviceType;
        bool isActive;
        uint256 lastDataTimestamp;
        uint256 totalDataPoints;
        string location;
    }
    
    struct DataPoint {
        string deviceId;
        string dataType;
        string dataValue;
        uint256 timestamp;
        bytes32 dataHash;
        bool isVerified;
    }
    
    mapping(string => IoTDevice) public devices;
    mapping(bytes32 => DataPoint) public dataPoints;
    mapping(address => string[]) public ownerDevices;
    
    string[] public allDeviceIds;
    bytes32[] public allDataHashes;
    
    event DeviceRegistered(string indexed deviceId, address indexed owner, string deviceType);
    event DataSubmitted(string indexed deviceId, bytes32 indexed dataHash, uint256 timestamp);
    event DataVerified(bytes32 indexed dataHash, address indexed verifier);
    event DeviceStatusChanged(string indexed deviceId, bool isActive);
    
    modifier onlyDeviceOwner(string memory _deviceId) {
        require(devices[_deviceId].owner == msg.sender, "Not device owner");
        _;
    }
    
    modifier deviceExists(string memory _deviceId) {
        require(bytes(devices[_deviceId].deviceId).length > 0, "Device does not exist");
        _;
    }
    
    /**
     * @dev Register a new IoT device on the blockchain
     * @param _deviceId Unique identifier for the device
     * @param _deviceType Type of the device (sensor, actuator, etc.)
     * @param _location Physical location of the device
     */
    function registerDevice(
        string memory _deviceId,
        string memory _deviceType,
        string memory _location
    ) external {
        require(bytes(_deviceId).length > 0, "Device ID cannot be empty");
        require(bytes(devices[_deviceId].deviceId).length == 0, "Device already registered");
        
        devices[_deviceId] = IoTDevice({
            owner: msg.sender,
            deviceId: _deviceId,
            deviceType: _deviceType,
            isActive: true,
            lastDataTimestamp: block.timestamp,
            totalDataPoints: 0,
            location: _location
        });
        
        ownerDevices[msg.sender].push(_deviceId);
        allDeviceIds.push(_deviceId);
        
        emit DeviceRegistered(_deviceId, msg.sender, _deviceType);
    }
    
    /**
     * @dev Submit data from an IoT device with cryptographic verification
     * @param _deviceId Device identifier submitting the data
     * @param _dataType Type of data being submitted (temperature, humidity, etc.)
     * @param _dataValue The actual data value
     */
    function submitData(
        string memory _deviceId,
        string memory _dataType,
        string memory _dataValue
    ) external onlyDeviceOwner(_deviceId) deviceExists(_deviceId) {
        require(devices[_deviceId].isActive, "Device is not active");
        require(bytes(_dataType).length > 0, "Data type cannot be empty");
        require(bytes(_dataValue).length > 0, "Data value cannot be empty");
        
        bytes32 dataHash = keccak256(abi.encodePacked(_deviceId, _dataType, _dataValue, block.timestamp, msg.sender));
        
        dataPoints[dataHash] = DataPoint({
            deviceId: _deviceId,
            dataType: _dataType,
            dataValue: _dataValue,
            timestamp: block.timestamp,
            dataHash: dataHash,
            isVerified: false
        });
        
        devices[_deviceId].lastDataTimestamp = block.timestamp;
        devices[_deviceId].totalDataPoints++;
        allDataHashes.push(dataHash);
        
        emit DataSubmitted(_deviceId, dataHash, block.timestamp);
    }
    
    /**
     * @dev Verify submitted data (can be called by any address for decentralized verification)
     * @param _dataHash Hash of the data to verify
     */
    function verifyData(bytes32 _dataHash) external {
        require(dataPoints[_dataHash].timestamp > 0, "Data point does not exist");
        require(!dataPoints[_dataHash].isVerified, "Data already verified");
        
        // Simple verification logic - in production, this could involve more complex validation
        dataPoints[_dataHash].isVerified = true;
        
        emit DataVerified(_dataHash, msg.sender);
    }
    
    /**
     * @dev Get device information
     * @param _deviceId Device identifier to query
     * @return Device struct containing all device information
     */
    function getDevice(string memory _deviceId) external view deviceExists(_deviceId) returns (IoTDevice memory) {
        return devices[_deviceId];
    }
    
    /**
     * @dev Get data point information
     * @param _dataHash Hash of the data point to query
     * @return DataPoint struct containing all data information
     */
    function getDataPoint(bytes32 _dataHash) external view returns (DataPoint memory) {
        require(dataPoints[_dataHash].timestamp > 0, "Data point does not exist");
        return dataPoints[_dataHash];
    }
    
    /**
     * @dev Get all devices owned by a specific address
     * @param _owner Address of the device owner
     * @return Array of device IDs owned by the address
     */
    function getOwnerDevices(address _owner) external view returns (string[] memory) {
        return ownerDevices[_owner];
    }
    
    /**
     * @dev Toggle device active status (only device owner)
     * @param _deviceId Device identifier to update
     */
    function toggleDeviceStatus(string memory _deviceId) external onlyDeviceOwner(_deviceId) deviceExists(_deviceId) {
        devices[_deviceId].isActive = !devices[_deviceId].isActive;
        emit DeviceStatusChanged(_deviceId, devices[_deviceId].isActive);
    }
    
    /**
     * @dev Get total number of registered devices
     * @return Total count of devices
     */
    function getTotalDevices() external view returns (uint256) {
        return allDeviceIds.length;
    }
    
    /**
     * @dev Get total number of data points submitted
     * @return Total count of data points
     */
    function getTotalDataPoints() external view returns (uint256) {
        return allDataHashes.length;
    }
}
