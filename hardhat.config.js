require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
require("hardhat-gas-reporter");
require("solidity-coverage");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
	const accounts = await hre.ethers.getSigners();

	for (const account of accounts) {
		console.log(account.address);
	}
});

const accounts = {
	mnemonic:
		process.env.MNEMONIC ||
		"test test test test test test test test test test test junk",
};

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	defaultNetwork: "hardhat",
	namedAccounts: {
		deployer: {
			default: 0,
		},
	},
	gasReporter: {
		enabled: process.env.REPORT_GAS !== undefined,
		currency: "USD",
	},
	etherscan: {
		apiKey: process.env.ETHERSCAN_API_KEY,
	},
	networks: {
		hardhat: {
			chainId: 1337,
			accounts,
		},
		plstestnet: {
			url: "https://rpc.v2.testnet.pulsechain.com",
			chainId: 940,
			accounts:
				process.env.PRIVATE_KEY !== undefined
					? [process.env.PRIVATE_KEY]
					: [],
			live: true,
			saveDeployments: true,
			tags: ["test"],
			gasPrice: 50000000000,
			gas: 8000000,
		},
		movrmainnet: {
			url: "https://rpc.moonriver.moonbeam.network",
			chainId: 1285,
			accounts:
				process.env.PRIVATE_KEY !== undefined
					? [process.env.PRIVATE_KEY]
					: [],
			live: true,
			saveDeployments: true,
			tags: ["staging"],
			gasPrice: 5000000000,
			gas: 8000000,
		},

		bsctestnet: {
			url: "https://data-seed-prebsc-1-s1.binance.org:8545",
			chainId: 97,
			accounts:
				process.env.PRIVATE_KEY !== undefined
					? [process.env.PRIVATE_KEY]
					: [],
			live: true,
			saveDeployments: true,
			tags: ["testnet"],
			gasPrice: 50000000000,
			gas: 8000000,
		},
	},
	solidity: {
		compilers: [
			{
				version: "0.6.12",
				settings: {
					optimizer: {
						enabled: true,
						runs: 999999,
					},
				},
			},
			{
				version: "0.8.0",
				settings: {
					optimizer: {
						enabled: true,
						runs: 999999,
					},
				},
			},
		],
	},
};
