import { contractABI } from './contract_abi.js';
import { contractAddress } from './contract_abi.js';
import { infuraProvider } from './contract_abi.js';

let web3, web3Infura, contract, contractInfura, userAddress;

async function init() {
    if (typeof window.ethereum !== 'undefined') {
        web3 = new Web3(window.ethereum);
        web3Infura = new Web3(new Web3.providers.HttpProvider(infuraProvider));
        contract = new web3.eth.Contract(contractABI, contractAddress);
        contractInfura = new web3Infura.eth.Contract(contractABI, contractAddress);
    } else {
        alert('Please install MetaMask to use this dApp.');
    }
}

// ASSET POOL SIZE
window.onload = async function() {
    await init();

    try {
        const result = await contract.methods.getBalance().call();
        document.getElementById('pool_size').innerHTML =  `Asset Pool Size: ${result/1000000000000000000} ETH`;
    } catch (error) {
        console.error('Error calling myFunction:', error);
    }
};

// CONNECTING
document.getElementById('connect').addEventListener('click', async () => {
    if (!web3) {
        return;
    }
    try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        userAddress = accounts[0];
        console.log('Connected address:', userAddress);
        document.getElementById('connect').innerHTML =  `Connected address: ${userAddress}`;
    } catch (error) {
        console.error('Error connecting to MetaMask:', error);
    }
});

// LENDING / DEPOSITING
document.getElementById('deposit').addEventListener('click', async () => {
    if (!userAddress) {
        alert('Please connect to MetaMask first.');
        return;
    }
    const ethAmount = document.getElementById('ethAmount_lend').value || 0;
    const valueInWei = web3.utils.toWei(ethAmount, 'ether');

    try {
        await contract.methods.deposit().send({ from: userAddress, value: valueInWei });
        alert('Deposit Successful');
        const result = await contract.methods.getBalance().call();
        document.getElementById('pool_size').innerHTML =  `Asset Pool Size: ${result/1000000000000000000} ETH`;
    } catch (error) {
        console.error('Error depositing:', error);
    }
});

// WITHDRAWING / BORROWING
document.getElementById('withdraw').addEventListener('click', async () => {
    if (!userAddress) {
        alert('Please connect to MetaMask first.');
        return;
    }
    const ethAmount = document.getElementById('ethAmount_borrow').value || 0;
    const valueInWei = web3.utils.toWei(ethAmount, 'ether');

    try {
        const privateKey = '978c72c42ea37e9a2b48534f6cc2940db4d999ea3ce1e4869d1b4c4eb4201e19';
        const account = web3Infura.eth.accounts.privateKeyToAccount(privateKey);
        const nonce = await web3Infura.eth.getTransactionCount(account.address);
        const gasPrice = await web3Infura.eth.getGasPrice();
        const gasLimit = 100000;

        const withdrawTx = {
            from: account.address,
            to: contractAddress,
            gas: gasLimit,
            gasPrice: gasPrice,
            nonce: nonce,
            value: valueInWei,
            data: contractInfura.methods.depositTo(userAddress).encodeABI()
        };
    
        const signedTx = await account.signTransaction(withdrawTx);
        const txReceipt = await web3Infura.eth.sendSignedTransaction(signedTx.rawTransaction);
        alert('Withdraw successful:', txReceipt);
        const result = await contract.methods.getBalance().call();
        document.getElementById('pool_size').innerHTML =  `Asset Pool Size: ${result/1000000000000000000} ETH`;
    } catch (error) {
        console.error('Error withdrawing:', error);
    }
});

init();    
