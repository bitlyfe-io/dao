const Web3 = require('web3');

const protocol = "http";
const ip = "localhost";
const port = 9650;

module.exports = {
  networks: {
    development: {
      provider: function() {
       return new Web3.providers.HttpProvider(`${protocol}://${ip}:${port}/ext/bc/C/rpc`)
      },
      from: "0x1258f072cb913c42fcbad66cbd0e0d099d5e1d4f",
      network_id: "*",
      gas: 8000000,
      gasPrice: 470000000000
    }
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