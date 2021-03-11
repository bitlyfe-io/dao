const Migrations = artifacts.require("Migrations");

module.exports = function (deployer) {
  deployer.deploy(Migrations, {
    from: "0x1258F072CB913c42FCBad66cbd0e0D099D5E1d4f"
  });
};
