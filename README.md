HealthcareGovernance Smart Contract (Simple Explanation)
What It Does:
This smart contract helps patients and doctors manage access to healthcare records securely.
It stores only encrypted references (like IPFS links), not real medical data.

Roles:
- Admin: Registers patients and doctors.
- Patient: Adds their medical data and decides who can see it.
- Doctor: Requests access to patient data.

Data Records:
Each patient has records with:
- dataHash: a unique ID or IPFS link
- description: short info like "Blood Test - Oct 2025"
- timestamp: when it was added

Adding Records:
Patients can add records using addDataRecord().
The function checks that:
- The data hash and description are not empty.
- The sender is a registered patient.

Granting & Revoking Access:
Patients can give or remove access for doctors using:
- grantAccess(address)
- revokeAccess(address)

Requesting Access:
Doctors can request permission to view patient records using requestAccess().
There’s a 5-minute cooldown so they can’t spam requests.
Viewing Records:
A user can view data if they are the patient or have permission.
The function viewDataRecords(patient, start, end) uses pagination,
so it only shows a limited range of records to save gas.

Admin Setup:
Admins can add new users:
- registerPatient(address)
- registerDoctor(address)

Security Features:
- Validates input fields (no empty strings or zero addresses)
- Uses role-based access control (Admin, Patient, Doctor)
- Prevents spam requests (cooldown timer)
- Future-ready for off-chain verification (e.g., checking IPFS data


addDataRecord       | Patient       | Adds encrypted data reference
grantAccess         | Patient       | Allows doctor to view data
revokeAccess        | Patient       | Removes doctor’s access
requestAccess       | Doctor        | Requests permission
viewDataRecords     | Patient/Doctor| Views records if allowed
registerPatient     | Admin         | Adds a patient
registerDoctor      | Admin         | Adds a doctor
