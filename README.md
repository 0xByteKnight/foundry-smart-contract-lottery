# 🎰 Foundry Smart Contract Lottery

![License](https://img.shields.io/badge/license-MIT-green)  
![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.28-blue)  
![Foundry](https://img.shields.io/badge/Built%20With-Foundry-orange)  

## 📌 Overview

**Foundry Smart Contract Lottery** is a decentralized, transparent, and autonomous lottery system built using Solidity. This smart contract enables users to participate in a lottery where a winner is randomly selected after a specified duration.

This repository contains the smart contract code, test scripts, and deployment instructions for the lottery system.

---

## ⚙️ Features

✔️ **Decentralized Lottery** – Users can enter the lottery by sending ETH to the contract.  
✔️ **Random Winner Selection** – A random participant is chosen as the winner.  
✔️ **Automated Prize Distribution** – The contract automatically transfers winnings.  
✔️ **Secure and Transparent** – Smart contract logic ensures fairness.  

---

## 🏗 Smart Contract Architecture

The system consists of the following core contracts:

### 🔹 [`Raffle.sol`](src/Raffle.sol)
- Manages user participation and winner selection.
- Implements randomness for selecting a winner.
- Handles ETH transfers for lottery entries and payouts.

---

## 🚀 Installation & Setup

Ensure you have **Foundry** installed. If not, install it using:

```sh
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 1️⃣ Clone the repository:

```sh
git clone https://github.com/0xByteKnight/foundry-smart-contract-lottery.git
cd foundry-smart-contract-lottery
```

### 2️⃣ Install dependencies:

```sh
forge install
```

### 3️⃣ Compile contracts:

```sh
forge build
```

### 4️⃣ Run tests:

```sh
forge test
```

---

## 📜 Usage

### 🎟 Entering the Lottery
Users can enter the lottery by sending ETH to the contract.

```solidity
lottery.enterLottery{value: 0.1 ether}();
```

### 🏆 Picking a Winner
The contract selects a random winner after a predetermined time.

```solidity
lottery.pickWinner();
```

### 💰 Withdrawing Winnings
The winner automatically receives the lottery pool balance.

```solidity
lottery.claimWinnings();
```

---

## 🏗 Development & Contribution

💡 Found a bug? Have an idea to improve the lottery? Contributions are welcome!  

### ✅ Steps to Contribute:
1. **Fork** this repository.  
2. **Create** a new branch: `git checkout -b feature-xyz`.  
3. **Commit** your changes: `git commit -m "Add feature xyz"`.  
4. **Push** to your fork and create a **Pull Request**.  

---

## 🔐 Security Considerations

- **Fair randomness** should be ensured to prevent manipulation.
- **Reentrancy protection** should be implemented to secure ETH withdrawals.
- **Gas optimization** should be considered for efficient transactions.

---

## 📜 License

This project is licensed under the **MIT License** – feel free to use and modify it.  

---

## 🔗 Connect with Me  

💼 **GitHub**: [0xByteKnight](https://github.com/0xByteKnight)  
🐦 **Twitter/X**: [@0xByteKnight](https://twitter.com/0xByteKnight)  
