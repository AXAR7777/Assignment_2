// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
 * Healthcare Data Governance Smart Contract (Enhanced)
 * ----------------------------------------------------
 * Features:
 * - Patients add encrypted data references (not raw data)
 * - Doctors request, gain, or lose access with permissions
 * - Immutable audit trail
 * - Input validation and access control
 * - Pagination to prevent high gas on large datasets
 * - Optional off-chain integrity verification (future oracle support)
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

contract HealthcareGovernance is AccessControl {

    // -------------------- Roles --------------------
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");

    // -------------------- Structs --------------------
    struct DataRecord {
        string dataHash;      // Encrypted pointer (e.g., IPFS CID)
        string description;   // Summary (e.g., "MRI Report - Oct 2025")
        uint256 timestamp;    // When record was added
    }

    // -------------------- State --------------------
    mapping(address => DataRecord[]) private patientRecords;             // Patient → Records
    mapping(address => mapping(address => bool)) private doctorAccess;   // Patient → Doctor → Access
    mapping(address => uint256) private lastAccessRequest;               // Cooldown tracker

    // -------------------- Events --------------------
    event DataAdded(address indexed patient, string dataHash, string description, uint256 timestamp);
    event AccessRequested(address indexed doctor, address indexed patient);
    event AccessGranted(address indexed patient, address indexed doctor);
    event AccessRevoked(address indexed patient, address indexed doctor);

    // -------------------- Constructor --------------------
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // -------------------- Modifiers --------------------
    modifier onlyValidAddress(address _addr) {
        require(_addr != address(0), "Invalid address: zero address");
        _;
    }

    // -------------------- Core Functions --------------------

    // Patients add metadata for off-chain medical records
    function addDataRecord(string memory _dataHash, string memory _description)
        public
        onlyRole(PATIENT_ROLE)
    {
        require(bytes(_dataHash).length > 0, "Data hash required");
        require(bytes(_description).length > 0, "Description required");

        patientRecords[msg.sender].push(
            DataRecord({
                dataHash: _dataHash,
                description: _description,
                timestamp: block.timestamp
            })
        );

        emit DataAdded(msg.sender, _dataHash, _description, block.timestamp);

        // Optional future enhancement: 
        // Verify off-chain availability via oracle callback.
    }

    // Doctors request access to patient data
    function requestAccess(address _patient)
        public
        onlyRole(DOCTOR_ROLE)
        onlyValidAddress(_patient)
    {
        // Front-running mitigation: simple cooldown of 5 minutes
        require(
            block.timestamp - lastAccessRequest[msg.sender] > 5 minutes,
            "Cooldown: wait before requesting again"
        );
        lastAccessRequest[msg.sender] = block.timestamp;

        emit AccessRequested(msg.sender, _patient);
    }

    // Patient grants access to a doctor
    function grantAccess(address _doctor)
        public
        onlyRole(PATIENT_ROLE)
        onlyValidAddress(_doctor)
    {
        require(hasRole(DOCTOR_ROLE, _doctor), "Address is not a registered doctor");
        doctorAccess[msg.sender][_doctor] = true;
        emit AccessGranted(msg.sender, _doctor);
    }

    // Patient revokes doctor access
    function revokeAccess(address _doctor)
        public
        onlyRole(PATIENT_ROLE)
        onlyValidAddress(_doctor)
    {
        doctorAccess[msg.sender][_doctor] = false;
        emit AccessRevoked(msg.sender, _doctor);
    }

    // Paginated record view to avoid gas overflow on large arrays
    function viewDataRecords(
        address _patient,
        uint256 startIndex,
        uint256 endIndex
    )
        public
        view
        returns (DataRecord[] memory)
    {
        require(
            msg.sender == _patient || doctorAccess[_patient][msg.sender],
            "Access denied"
        );
        require(endIndex > startIndex, "Invalid range");

        uint256 total = patientRecords[_patient].length;
        if (endIndex > total) endIndex = total;

        uint256 len = endIndex - startIndex;
        DataRecord[] memory records = new DataRecord[](len);

        for (uint256 i = 0; i < len; i++) {
            records[i] = patientRecords[_patient][startIndex + i];
        }

        return records;
    }

    // -------------------- Admin Functions --------------------
    function registerPatient(address _patient)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyValidAddress(_patient)
    {
        _grantRole(PATIENT_ROLE, _patient);
    }

    function registerDoctor(address _doctor)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyValidAddress(_doctor)
    {
        _grantRole(DOCTOR_ROLE, _doctor);
    }
}
