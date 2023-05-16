import { contractABI, contractAddress } from "./Contract_info.js";

let web3, userAddress, contract;

const multiplier = 10 ** 18;

function isFloat(value) {
  return /^-?\d*(\.\d+)?$/.test(value);
}

async function init() {
  if (typeof window.ethereum !== "undefined") {
    web3 = new Web3(window.ethereum);
    contract = new web3.eth.Contract(contractABI, contractAddress);
  } else {
    alert("Please install MetaMask to use this dApp.");
  }
}

// PROFILE ON LOAD

window.onload = async function () {
  await init(); // Call the init function to initialize web3 and contract

  if (!web3) {
    return;
  }

  try {
    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });

    const userAddress = accounts[0];
    const user_data = await contract.methods
      .getUserData()
      .call({ from: userAddress });
    const lenderInterest = await contract.methods
      .lendersInterest()
      .call({ from: userAddress });
    const a_interest = lenderInterest + user_data[1][2];
    const firstFourChars = userAddress.substring(0, 4);
    const lastFourChars = userAddress.substring(userAddress.length - 4);

    console.log(userAddress);
    document.getElementById("ConnectedText").innerHTML =
      "Your address: " +
      firstFourChars +
      "..." +
      lastFourChars +
      "<br>" +
      "Reputation Points: " +
      user_data[2] / multiplier;

    document.getElementById("item1").textContent =
      "ETH lent to the platform: " + user_data[1][0] / multiplier + " ETH";
    document.getElementById("item2").textContent =
      "Accrued Interest: " + a_interest / multiplier + " ETH";
  } catch (error) {
    console.log(error);
  }
};

// WITHDRAW INT

document
  .getElementById("lender_withdraw_interest")
  .addEventListener("click", async () => {
    if (!web3) {
      return;
    }
    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    const userAddress = accounts[0];
    try {
      // Display processing alert

      const transaction = contract.methods
        .lenderWithdrawInterest()
        .send({ from: userAddress });

      const processingAlert = document.getElementById("processingAlert");
      processingAlert.style.display = "block";

      // Listen for the transaction confirmation
      transaction
        .on("confirmation", (confirmationNumber, receipt) => {
          console.log("Transaction confirmed:", receipt);
        })
        .on("error", (error) => {
          console.log("Transaction error:", error);
          // Hide processing alert on error
          processingAlert.style.display = "none";
        });

      // Wait for the transaction to be mined
      await transaction;

      // Hide processing alert
      processingAlert.style.display = "none";
      alert("Transaction completed!");
      window.location.reload();
    } catch (error) {
      console.log(error);
    }
  });

// WITHDRAW ETH

document
  .getElementById("withdraw_amt_button")
  .addEventListener("click", async () => {
    if (!web3) {
      return;
    }

    const amount = prompt("Enter the amount to withdraw (in ETH):");
    if (!isFloat(amount)) {
      alert("Invalid amount. Please enter a valid float value.");
      return;
    }

    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    const userAddress = accounts[0];

    try {
      // Display processing alert
      const processingAlert = document.getElementById("processingAlert");
      processingAlert.style.display = "block";

      const interest = await contract.methods
        .lenderWithdrawPrincipal(amount * multiplier)
        .send({ from: userAddress });
      console.log(interest); // handle success

      // Hide processing alert
      processingAlert.style.display = "none";
      alert("Transaction completed!");
      window.location.reload();
    } catch (error) {
      console.log(error);
    }
  });

// WITHDRAW BOTH

document
  .getElementById("lender_withdraw_both")
  .addEventListener("click", async () => {
    if (!web3) {
      return;
    }
    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    const userAddress = accounts[0];
    try {
      // Display processing alert
      const processingAlert = document.getElementById("processingAlert");
      processingAlert.style.display = "block";

      const interest = await contract.methods
        .lenderWithdrawBoth()
        .send({ from: userAddress });
      console.log(interest); // handle success

      // Hide processing alert
      processingAlert.style.display = "none";
      alert("Transaction completed!");

      // Reload the page
      window.location.href = "./FirstPage.html";
    } catch (error) {
      console.log(error);
    }
  });

init();
