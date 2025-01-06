# 🎲 Smart Contract Lottery

## 📚 Overview
The **Smart Contract Lottery** is a decentralized application (dApp) built on the Ethereum blockchain. It leverages Chainlink's VRF (Verifiable Random Function) for provable randomness and automation to manage lottery operations. Participants can enter the lottery by paying a fee, and a winner is randomly selected based on verifiable random numbers provided by Chainlink.

This project demonstrates:
- Decentralized lottery mechanics.
- Secure and provably fair randomness.
- Automated contract interactions using Chainlink Automation (Keepers).

---

## 🚀 Features
- **Fair Randomness**: Uses Chainlink VRF to ensure unbiased and tamper-proof winner selection.
- **Automated Execution**: Automates lottery processes, such as determining a winner, using Chainlink Automation.
- **Dynamic Configuration**: Supports configuration of entrance fees, intervals, and gas limits.
- **Integration Tests**: Comprehensive testing to ensure the integrity of the smart contract.

---

## 🛠️ Technology Stack
- **Smart Contracts**: Written in Solidity (`^0.8.28`).
- **Testing & Deployment**: Built using Foundry.
- **Chainlink Services**:
  - VRF v2.5 for randomness.
  - Automation for upkeep.
- **Mock Contracts**: Includes mocks for local testing of Chainlink services.

---

## 🗂️ Project Structure
```plaintext
├── src/
│   ├── Raffle.sol             # The main smart contract for the lottery.
├── script/
│   ├── DeployRaffle.s.sol     # Deployment script for the Raffle contract.
│   ├── HelperConfig.s.sol     # Configuration helper for different networks.
│   ├── Interactions.s.sol     # Contains scripts for subscription creation, funding, and consumer addition.
├── test/
│   ├── RaffleIntegrationTest.sol # Integration tests for the Raffle contract and related scripts.
│   ├── UnitTests.sol          # Unit tests for individual contract functions.
├── test/mocks/
│   ├── LinkToken.sol          # Mock LinkToken contract for testing.
```

---

## 💪 Tests
This project includes unit and integration tests written using Foundry:
- **Test Coverage**:
  - Contract deployment.
  - Subscription creation, funding, and consumer addition.
  - Lottery workflows (e.g., entering the lottery, winner selection).
  - Individual function behaviors and edge cases.
- **Run Tests**:
  ```bash
  forge test
  ```
- **Unit Tests**:
  Test specific functionalities and edge cases of the `Raffle` contract, such as:
  - Invalid entries.
  - Correct fee requirements.
  - Proper resetting after a winner is selected.
- **Integration Tests**:
  Validate the interaction between `Raffle` and Chainlink services (VRF and Automation).

---

## 💻 Usage

### Prerequisites
- Node.js and npm installed.
- Foundry installed for testing and deployment.

### Install Dependencies
```bash
npm install
```

### Deploy the Contract
```bash
forge script script/DeployRaffle.s.sol --broadcast --rpc-url <YOUR_RPC_URL>
```

### Run Tests
```bash
forge test
```

---

## 🔗 Chainlink Integration
- **Chainlink VRF**: Ensures provably fair randomness for winner selection.
- **Chainlink Automation**: Automates key processes like checking conditions and selecting a winner.

---

## 🖋️ License
This project is licensed under the MIT License. See the LICENSE file for details.
