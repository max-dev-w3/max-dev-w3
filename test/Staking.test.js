const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MaxDevStakingFixed - S-Tier Test Suite", function () {
  let stakingContract;
  let owner;
  let user1;
  let user2;
  let stakingTokenAddress;
  let rewardTokenAddress;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // В качестве заглушек для адресов токенов передадим валидные адреса пользователей,
    // чтобы проверить исключительно базовую логику деплоя и инициализации
    stakingTokenAddress = user1.address;
    rewardTokenAddress = user2.address;

    const StakingFactory = await ethers.getContractFactory("MaxDevStakingFixed");
    stakingContract = await StakingFactory.deploy(stakingTokenAddress, rewardTokenAddress);
    await stakingContract.deployed();
  });

  describe("Deployment", function () {
    it("Should set the correct token addresses", async function () {
      expect(await stakingContract.stakingToken()).to.equal(stakingTokenAddress);
      expect(await stakingContract.rewardToken()).to.equal(rewardTokenAddress);
    });

    it("Should initialize with zero total supply", async function () {
      expect(await stakingContract.totalSupply()).to.equal(0);
    });
  });
});
