// Replace this with the ABI of your smart contract
const contractABI = [
	{
		"inputs": [],
		"name": "myPayableFunction",
		"outputs": [],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "Received",
		"type": "event"
	}
];

// Replace this with the deployed smart contract address
const contractAddress = '0x095127D9f3e491a24775f7131d84f07673EF2bC0';

window.addEventListener('load', async () => {
    if (window.ethereum) {
        window.web3 = new Web3(window.ethereum);
        try {
            await window.ethereum.request({ method: 'eth_requestAccounts' });
        } catch (error) {
            console.error('User denied account access');
        }
    } else {
        console.error('No Ethereum provider detected');
    }

    const myContract = new window.web3.eth.Contract(contractABI, contractAddress);
    const transferButton = document.getElementById('transferButton');
    transferButton.addEventListener('click', async () => {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        const from = accounts[0];
        
        const ethAmount = document.getElementById('ethAmount').value || 0; // Get the value from the input field
        const valueInWei = window.web3.utils.toWei(ethAmount, 'ether'); // Convert the input value to Wei
    
        const gas = await myContract.methods.myPayableFunction().estimateGas({ from, value: valueInWei });
    
        myContract.methods.myPayableFunction().send({ from, value: valueInWei, gas }, (error, transactionHash) => {
            const messageElement = document.getElementById('message');
            
            if (error) {
                console.error('Transaction failed:', error);
                messageElement.textContent = 'Transaction failed. Please check the console for more details.';
            } else {
                console.log('Transaction successful:', transactionHash);
                messageElement.textContent = `Transaction successful! Transaction hash: ${transactionHash}`;
            }
        });
    });

});    