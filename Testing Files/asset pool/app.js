const contractABI = [
	{
		"inputs": [],
		"name": "deposit",
		"outputs": [],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address payable",
				"name": "recipient",
				"type": "address"
			}
		],
		"name": "depositTo",
		"outputs": [],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"inputs": [],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "withdraw",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "balance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getBalance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "owner",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
];
        const contractAddress = '0xaA7E26026eDcbbF8885c215a6ED80Df8eA995c7C';
        const infuraApiKey = '0a9b317146bb4324b7f96686521fbf16';
        const infuraProvider = `https://sepolia.infura.io/v3/0a9b317146bb4324b7f96686521fbf16`;
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

        document.getElementById('connect').addEventListener('click', async () => {
            if (!web3) {
                return;
            }
            try {
                const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
                userAddress = accounts[0];
                console.log('Connected address:', userAddress);
				console.log(accounts)
				alert('connected')
            } catch (error) {
                console.error('Error connecting to MetaMask:', error);
            }
        });

        document.getElementById('deposit').addEventListener('click', async () => {
            if (!userAddress) {
                alert('Please connect to MetaMask first.');
                return;
            }
            const ethAmount = document.getElementById('ethAmount').value || 0; // Get the value from the input field
            const valueInWei = web3.utils.toWei(ethAmount, 'ether'); // Convert the input value to Wei
            //const amount = web3.utils.toWei('0.1', 'ether'); // Change the amount as needed
            try {
                await contract.methods.deposit().send({ from: userAddress, value: valueInWei });
                console.log('Deposit successful');
            } catch (error) {
                console.error('Error depositing:', error);
            }
        });

        document.getElementById('withdraw').addEventListener('click', async () => {
            if (!userAddress) {
                alert('Please connect to MetaMask first.');
                return;
            }

            const amount = web3.utils.toWei('0.1', 'ether'); // Change the amount as needed
            try {
                const privateKey = '978c72c42ea37e9a2b48534f6cc2940db4d999ea3ce1e4869d1b4c4eb4201e19'; // WARNING: Do not store your private key in client-side code!
				const account = web3Infura.eth.accounts.privateKeyToAccount(privateKey);
				const nonce = await web3Infura.eth.getTransactionCount(account.address);
				const gasPrice = await web3Infura.eth.getGasPrice();
				const gasLimit = 100000; // Adjust the gas limit as needed

				const withdrawTx = {
					from: account.address,
					to: contractAddress,
					gas: gasLimit,
					gasPrice: gasPrice,
					nonce: nonce,
					value: amount,
					data: contractInfura.methods.depositTo(userAddress).encodeABI()
				};

				const signedTx = await account.signTransaction(withdrawTx);
				const txReceipt = await web3Infura.eth.sendSignedTransaction(signedTx.rawTransaction);
				alert('Withdraw successful:', txReceipt);

                console.error('Please implement the withdraw function using contractInfura and the Infura provider.');
            } catch (error) {
                console.error('Error withdrawing:', error);
            }
        });

        init();