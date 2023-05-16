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

window.onload = async () => {
  if (!web3) {
    return;
  }

  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });

  const userAddress = accounts[0];

  try {
    const user_data = await contract.methods
      .getUserData()
      .call({ from: userAddress });

    const int = await contract.methods
      .calculateMinimumDeposit()
      .call({ from: userAddress });

    document.getElementById("item1_b").textContent =
      "ETH Borrowed: " + user_data[0][0] / multiplier + " ETH";
    document.getElementById("item2_b").textContent =
      "Accrued Interest: " + int[0] / multiplier + " ETH";
    document.getElementById("item3_b").textContent =
      "Time Remaining: " + int[1];
    document.getElementById("item4_b").textContent =
      "Reputation: " + user_data[2] / multiplier;
  } catch (error) {
    console.log(error);
  }
};

document.getElementById("pay_int").addEventListener("click", async () => {
  if (!web3) {
    return;
  }
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });
  const userAddress = accounts[0];
  try {
    const int = await contract.methods
      .calculateMinimumDeposit()
      .call({ from: userAddress });

    // Display processing alert
    const processingAlert = document.getElementById("processingAlert");
    processingAlert.style.display = "block";

    await contract.methods
      .borrowerPayInterest()
      .send({ from: userAddress, value: parseInt(int[0]) + 10 ** 12 })
      .on("confirmation", (confirmationNumber, receipt) => {
        console.log("Transaction confirmed:", receipt);
      })
      .on("error", (error) => {
        console.log("Transaction error:", error);
        // Hide processing alert on error
        processingAlert.style.display = "none";
      });

    // Hide processing alert
    processingAlert.style.display = "none";

    // Show transaction complete pop-up

    alert("Transaction completed!");

    // Reload the page after a successful transaction
    window.location.reload();
  } catch (error) {
    console.log(error);
  }

  document.getElementById("pay_both").addEventListener("click", async () => {
    if (!web3) {
      console.log("yo");
      return;
    }
    console.log("yo");
    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    const userAddress = accounts[0];
    try {
      const int = await contract.methods
        .calculateMinimumDeposit()
        .call({ from: userAddress });
      const user_data = await contract.methods
        .getUserData()
        .call({ from: userAddress });
      await contract.methods
        .borrowerRepayLoan()
        .send({
          from: userAddress,
          value: parseInt(user_data[0][0]) + parseInt(int[0]) + 10 ** 9,
        })
        .then(function (receipt) {
          console.log(receipt);
        });
      // NOTE - ADD THE BUFFER
    } catch (error) {
      console.log(error);
    }
  });
});

init();
