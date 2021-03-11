const Migrations = artifacts.require("Migrations");

module.exports = function (deployer) {
  deployer.deploy(Migrations, {
    from: "0x1258f072cb913c42fcbad66cbd0e0d099d5e1d4f"
  });
};
