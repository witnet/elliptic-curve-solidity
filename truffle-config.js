module.exports = {
  networks: {
    local: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    development: {
      provider: require("ganache-cli").provider({ gasLimit: 100000000 }),
      network_id: "*",
    },
  },
  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD",
      gasPrice: 20,
    },
  },
  // Configure your compilers
  compilers: {
    solc: {
      // version: "0.5.1",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      //  evmVersion: "byzantium"
      },
    },
  },
}
