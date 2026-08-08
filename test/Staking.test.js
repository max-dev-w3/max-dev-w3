const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Metric Core - Vulnerability H-1 Exploit Simulation", function () {
  let fakePool;
  let attacker;
  let victim;
  let router;
  let mockToken;

  beforeEach(async function () {
    // Получаем аккаунты хакера, жертвы и условного роутера
    [attacker, victim, router] = await ethers.getSigners();

    // В реальном тесте здесь деплоился бы ERC20, но мы для наглядности 
    // используем сам контракт стейкинга или любой адрес как заглушку токена.
    // Развернем наш эксплойт-контракт
    const FakePoolFactory = await ethers.getContractFactory("FakeAttackPool");
    fakePool = await FakePoolFactory.deploy(router.address, victim.address, attacker.address);
    await fakePool.deployed();
  });

  describe("Exploit Execution", function () {
    it("Should successfully deploy the attack vector", async function () {
      expect(await fakePool.router()).to.equal(router.address);
      expect(await fakePool.victim()).to.equal(victim.address);
    });
  });
});
