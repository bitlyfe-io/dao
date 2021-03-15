const Web3 = require('web3');

const protocol = "http";
const ip = "localhost";
const port = 9650;
const mnemonic = "cb269e5b4f23848413c30a3bcf6735064b4204ddcb055a0ca81f4b218c6c1f00";

module.exports = {
  networks: {
    avax_testnet: {
      provider: function() {
       return new Web3.providers.HttpProvider(`${protocol}://${ip}:${port}/ext/bc/C/rpc`)
      },
      from: "0x1258F072CB913c42FCBad66cbd0e0D099D5E1d4f",
      network_id: "*",
      gas: 8000000,
      gasPrice: 470000000000
    },
    bsc_testnet: {
      provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      from: "0x369a2C0E52A27E975fC293A03d06D8fbf93586D5",
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    bsc_main: {
      provider: () => new HDWalletProvider(mnemonic, `https://bsc-dataseed1.binance.org`),
      from: "0x369a2C0E52A27E975fC293A03d06D8fbf93586D5",
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },
  mocha: {
    timeout: 100000
  },
  compilers: {
    solc: {
        version: "0.6.11",
        docker: false,
        parser: "solcjs",
        settings: {
          optimizer: {
            enabled: true,
            runs: 10000000
          }
      }
    }
  }
};