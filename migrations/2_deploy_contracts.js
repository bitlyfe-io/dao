const BitLyfe = artifacts.require("./contracts/BitLyfe.sol");

module.exports = function (deployer) {
  deployer.deploy(BitLyfe, {
    from: "0x1258f072cb913c42fcbad66cbd0e0d099d5e1d4f"
  });
};