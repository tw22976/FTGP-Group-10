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

// BALANCE
window.onload = async function () {
  if (!web3) {
    return;
  }
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });
  const userAddress = accounts[0];
  try {
    const admin_data = await contract.methods
      .getAdminData()
      .call({ from: userAddress });
    //const admim = await contract.methods.getProfit().call({ from: userAddress });

    console.log(parseInt(admin_data[3]));

    document.getElementById("pool_size").innerHTML =
      " ASSET POOL SIZE : " + admin_data[5] + " ETH";
    document.getElementById("total_borrowed").innerHTML =
      " TOTAL BORROWED : " + admin_data[2] + " ETH";
    document.getElementById("total_deposit").innerHTML =
      " TOTAL DEPOSITED : " + admin_data[3] + " ETH";
    document.getElementById("total_collateral").innerHTML =
      " TOTAL COLLATERAL : " + admin_data[4] + " CT";
    document.getElementById("profits").innerHTML =
      " PROFITS : " + admin_data[1];
    document.getElementById("base_int").innerHTML =
      " BASE INTEREST : " + admin_data[0] + "%";

    // document.getElementById('asset_pool_size').innerHTML = 'ASSET POOL SIZE : ' + balance / multiplier + ' ETH';
    // document.getElementById('show_profit').innerHTML = 'PROFITS : ' + profit
    // NOTE - ADD THE BUFFER
    ("");
  } catch (error) {
    console.log(error);
  }
};

// GET PROFIT

document.getElementById("get_profit").addEventListener("click", async () => {
  if (!web3) {
    return;
  }
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });
  const userAddress = accounts[0];
  const admin_data = await contract.methods
    .getAdminData()
    .call({ from: userAddress });
  if (parseInt(admin_data[1]) > 0) {
    try {
      await contract.methods
        .withdrawProfits(admin_data[1])
        .send({ from: userAddress })
        .then(function (receipt) {
          console.log(receipt);
        });
      // NOTE - ADD THE BUFFER
    } catch (error) {
      console.log(error);
    }
  } else {
    window.alert("YOU HAVE NO PROFITS TO WITHDRAW");
  }
});

init();
