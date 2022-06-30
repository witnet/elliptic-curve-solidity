module.exports = {
  plugins: ["solidity-coverage"],
  networks: {
    local: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
  },
  mocha: {
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD",
      gasPrice: 100,
      excludeContracts: ["Migrations"],
      src: "benchmark",
    },
  },
  compilers: {
    solc: {
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
      version: "0.8.15",
    },
  },
}
