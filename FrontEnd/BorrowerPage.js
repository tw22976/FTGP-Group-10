import { contractABI, contractAddress } from "./Contract_info.js";

let web3, contract;

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
  const firstFourChars = userAddress.substring(0, 4);
  const lastFourChars = userAddress.substring(userAddress.length - 4);

  try {
    const user_data = await contract.methods
      .getUserData()
      .call({ from: userAddress });

    const int = await contract.methods
      .calculateMinimumDeposit()
      .call({ from: userAddress });

    if (user_data[1][1] != parseInt(0)) {
      document.getElementById("lending").style.display = "block";
    }

    const base_int = await contract.methods
      .calculateInterestRate()
      .call({ from: userAddress });
    console.log(
      (110 - parseInt(user_data[0][2])) * 0.005 +
        (parseInt(base_int) + 200) / 100
    );

    document.getElementById("user_info").innerHTML =
      "Your address: " +
      firstFourChars +
      "..." +
      lastFourChars +
      "<br>" +
      "Reputation Points :" +
      user_data[2] / multiplier;

    document.getElementById("item1_b").textContent =
      "ETH Borrowed: " + parseInt(user_data[0][0]) / multiplier + " ETH";
    document.getElementById("item2_b").textContent =
      "Accrued Interest: " + parseInt(int[0]) / multiplier + " ETH";
    document.getElementById("item3_b").textContent =
      "Time Remaining: " + int[1] + "s";

    (
      (110 - parseInt(user_data[0][2])) * 0.005 +
      (parseInt(base_int) + 200) / 100
    ).toFixed(1) + "%";
  } catch (error) {
    console.log(error);
  }
};

// Lending Profile

document.getElementById("lending").addEventListener("click", function () {
  window.location.href = "./LendersPage.html";
});

// Pay Int

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
      .send({
        from: userAddress,
        value: 10 ** 15 + parseInt(int[0]),
      })
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
});

//Pay Both

document.getElementById("pay_both").addEventListener("click", async () => {
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
    const user_data = await contract.methods
      .getUserData()
      .call({ from: userAddress });

    const loan_info = document.getElementById("loan_info");

    loan_info.innerHTML =
      "Loan Amount: " +
      user_data[0][0] / multiplier +
      " ETH<br>" +
      "Accrued Interest: " +
      int[0] / multiplier +
      " ETH";
    loan_info.style.display = "block";
    // Display processing alert
    const processingAlert = document.getElementById("processingAlert");
    processingAlert.style.display = "block";
    console.log(parseInt(user_data[0][0]) + parseInt(int[0]), 10 ** 12);
    await contract.methods
      .borrowerRepayLoan()
      .send({
        from: userAddress,
        value: parseInt(user_data[0][0]) + parseInt(int[0]) + 10 ** 15,
      })
      .on("confirmation", (confirmationNumber, receipt) => {
        console.log("Transaction confirmed:", receipt);
      })
      .on("error", (error) => {
        console.log("Transaction error:", error);
        // Hide processing alert on error
        processingAlert.style.display = "none";
        loan_info.style.display = "none";
      });

    // Hide processing alert
    processingAlert.style.display = "none";
    loan_info.style.display = "none";
    // Show transaction complete pop-up
    alert("Transaction completed!");
    window.location.href = "./FirstPage.html";
  } catch (error) {
    console.log(error);
  }
});

// CONTRACT INFO

document.getElementById("owner").innerHTML =
  "OWNER: 0xB2e8a15dFD0EFBd022825DA12Fd061b858f19CD3 Change ";
document.getElementById("con_info").innerHTML =
  "CONTRACT ADDRESS: 0xB2e8a15dFD0EFBd022825DA12Fd061b858f19CD3";

init();
