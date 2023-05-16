// Web 3 Client

import { contractABI, contractAddress } from "./Contract_info.js";

let web3, userAddress, contract;

const multiplier = 10 ** 18;

async function init() {
  if (typeof window.ethereum !== "undefined") {
    web3 = new Web3(window.ethereum);
    contract = new web3.eth.Contract(contractABI, contractAddress);
  } else {
    alert("Please install MetaMask to use this dApp.");
  }
}

// Connect button

function connect() {
  var connectButton = document.getElementById("Connect");
  connectButton.style.display = "none";

  var connectedText = document.getElementById("ConnectedText");
  connectedText.style.display = "block";

  var connectedText = document.getElementById("profile");
  connectedText.style.display = "block";
}

// Connecting

document.getElementById("Connect").addEventListener("click", async () => {
  if (!web3) {
    return;
  }
  try {
    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    console.log("yo");
    const userAddress = accounts[0];
    const firstFourChars = userAddress.substring(0, 4);
    const lastFourChars = userAddress.substring(userAddress.length - 4);
    const user_data = await contract.methods
      .getUserData()
      .call({ from: userAddress });

    connect();
    document.getElementById("ConnectedText").innerHTML =
      "Your address: " +
      firstFourChars +
      "..." +
      lastFourChars +
      "<br>" +
      "Reputation Points :" +
      user_data[2] / multiplier;
  } catch (error) {
    console.error("Error connecting to MetaMask:", error);
  }
});

// Profile Button

document.getElementById("profile").addEventListener("click", async () => {
  if (!web3) {
    return;
  }
  try {
    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    const userAddress = accounts[0];
    const owner = await contract.methods.getOwner().call({ from: userAddress });
    const user_data = await contract.methods
      .getUserData()
      .call({ from: userAddress });
    console.log(user_data);
    if (userAddress.toLowerCase() === owner.toLowerCase()) {
      window.location.href = "./admin.html";
    } else if (parseInt(user_data[1][1]) !== 0) {
      window.location.href = "./LendersPage.html";
    } else if (parseInt(user_data[0][0]) !== 0) {
      window.location.href = "./BorrowerPage.html";
    } else {
      window.prompt("sometext", "defaultText");
    }
  } catch (error) {
    // Handle the error here
  }
});

// LEND ETH

document.getElementById("lend_eth").addEventListener("click", async () => {
  if (!web3) {
  }
  const lend_amount = document.getElementById("lend_amount").value * multiplier;

  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });
  userAddress = accounts[0];
  try {
    // call the lenderDeposit function and send the depositAmount in wei
    const transaction = contract.methods
      .lenderDeposit()
      .send({ from: userAddress, value: lend_amount })
      .then(function (receipt) {
        console.log(receipt);
        // handle success
      });
    await transaction;
    window.location.href = "./LendersPage.html";
  } catch (error) {
    console.log(error);
  } finally {
    console.log("This code always runs, whether there was an error or not.");
  }
});

//ETH TO WEI

document.getElementById("lend_amount").addEventListener("input", function () {
  const lendAmount = parseFloat(this.value);
  if (!isNaN(lendAmount)) {
    const weiValue = lendAmount * multiplier;
    document.getElementById("wei").value = weiValue;
  } else {
    document.getElementById("wei").value = "";
  }
});

//------------------------------------------------------
// BORROWER
// BORROW ETH

document.getElementById("borrow_eth").addEventListener("click", async () => {
  if (!web3) {
    return;
  }
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });
  const userAddress = accounts[0];
  const borrow_eth_amount =
    document.getElementById("borrow_eth_amount").value * multiplier;
  try {
    await contract.methods
      .borrowerDepositCollateral(
        borrow_eth_amount,
        document.getElementById("borrow_rep_use").value
      )
      .send({ from: userAddress });
  } catch (error) {
    console.log(error);
  }
});

// BORROWER PAY BOTH

init();
