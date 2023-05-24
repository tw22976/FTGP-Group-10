import { contractABI, contractAddress } from "./Contract_info.js";

let web3, userAddress, contract, base_int, rep_required, accounts;

const multiplier = 10 ** 18;

async function init() {
  if (typeof window.ethereum !== "undefined") {
    web3 = new Web3(window.ethereum);
    contract = new web3.eth.Contract(contractABI, contractAddress);
  } else {
    alert("Please install MetaMask to use this dApp.");
  }
}

window.onload = async function () {
  if (typeof window.ethereum === "undefined") {
    alert("MetaMask is not installed!");
    return;
  }

  const web3 = new Web3(window.ethereum);
  const contract = new web3.eth.Contract(contractABI, contractAddress);
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });

  const userAddress = accounts[0];
  base_int = await contract.methods
    .calculateInterestRate()
    .call({ from: userAddress });

  document.getElementById("base_int").innerHTML =
    "@ " + parseInt(base_int) / 100 + "%";
  document.getElementById("b_base").innerHTML =
    "@ " + Math.round((parseInt(base_int) / 100 + 2) * 100) / 100 + "%";

  document.getElementById("note").innerHTML =
    "(When 0 Reputation Token is used)";
};

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
      "Reputation Points: " +
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
    console.log("yooo");
    const userAddress = accounts[0];
    const owner = await contract.methods.getOwner().call({ from: userAddress });
    const user_data = await contract.methods
      .getUserData()
      .call({ from: userAddress });
    if (userAddress.toLowerCase() === owner.toLowerCase()) {
      window.location.href = "./admin.html";
    } else if (parseInt(user_data[0][0]) !== 0) {
      window.location.href = "./BorrowerPage.html";
    } else if (parseInt(user_data[1][1]) !== 0) {
      window.location.href = "./LendersPage.html";
    } else {
      alert("You Do not have any active transaction");
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
    document.getElementById("processing").innerHTML = "PROCESSING....";
    const transaction = contract.methods
      .lenderDeposit()
      .send({ from: userAddress, value: lend_amount })
      .then(function (receipt) {
        console.log(receipt);
        // handle success
      });
    await transaction;
    alert("Transaction Complete !!");
    document.getElementById("processing").style.display = "none";
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

// BORROW ETH
document.getElementById("borrow_eth").addEventListener("click", async () => {
  if (!web3) {
    return;
  }
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });
  const userAddress = accounts[0];
  const borrow_eth_amount = BigInt(
    document.getElementById("borrow_eth_amount").value * multiplier
  );

  console.log(borrow_eth_amount);
  try {
    // Retrieve user data
    document.getElementById("b_process").innerHTML = "PROCESSING....";
    const user_data = await contract.methods
      .getUserData()
      .call({ from: userAddress });
    console.log(document.getElementById("borrow_rep_use").value);
    if (user_data[0][0] == 0) {
      if (rep_required <= user_data[2]) {
        const transaction = contract.methods
          .borrowerDepositCollateral(
            borrow_eth_amount,
            document.getElementById("borrow_rep_use").value
          )
          .send({ from: userAddress });
        await transaction;
        alert("Transaction Complete");
        window.location.href = "./BorrowerPage.html";
      } else {
        alert("Not enough Reputation");
      }
    } else {
      alert(
        "You have taken a loan, Kindly click on profile to clear that loan !"
      );
    }
  } catch (error) {
    console.log(error);
  }
});

//ETH TO WEI

document
  .getElementById("borrow_eth_amount")
  .addEventListener("input", function () {
    const lendAmount = parseFloat(this.value);
    if (!isNaN(lendAmount)) {
      const weiValue = lendAmount * multiplier;
      document.getElementById("wei_b").value = weiValue;
    } else {
      document.getElementById("wei_b").value = "";
    }
    logValues();
  });

function logValues() {
  const sliderElement = document.getElementById("borrow_rep_use");
  const borrowEthInputElement = document.getElementById("borrow_eth_amount");

  // console.log("Slider Value: " + sliderElement.value);
  // console.log("Borrow Eth Input Value: " + borrowEthInputElement.value);
  rep_required =
    ((110 - sliderElement.value) * borrowEthInputElement.value) / 100;
  document.getElementById("borrow_info").innerHTML =
    "CT REQUIRED: " +
    (sliderElement.value * borrowEthInputElement.value) / 100 +
    " CT" +
    "<br>" +
    "REPUTATION REQUIRED: " +
    rep_required +
    "<br>" +
    "INT RATE: " +
    Math.round(
      (parseInt(base_int) / 100 +
        (110 - sliderElement.value) * 0.005 * 100 +
        2) *
        100
    ) /
      100;
}
document.getElementById("borrow_rep_use").addEventListener("input", logValues);

// CONTRACT INFO

document.getElementById("owner").innerHTML =
  "OWNER: 0xB2e8a15dFD0EFBd022825DA12Fd061b858f19CD3 Change ";
document.getElementById("con_info").innerHTML =
  "CONTRACT ADDRESS: 0xB2e8a15dFD0EFBd022825DA12Fd061b858f19CD3";

init();
