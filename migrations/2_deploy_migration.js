const Temperature = artifacts.require("Temperature");

module.exports = function (deployer) {
  deployer.deploy(Temperature, ['0xa1339b179e415550E7E20C859780E45c77752123']);  
};
