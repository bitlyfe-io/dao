const BitLyfe = artifacts.require("./contracts/BitLyfe.sol");

module.exports = function (deployer) {
  deployer.deploy(BitLyfe, {
    from: "0x1258F072CB913c42FCBad66cbd0e0D099D5E1d4f"
  });
};