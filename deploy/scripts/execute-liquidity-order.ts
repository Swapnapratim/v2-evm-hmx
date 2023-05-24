import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  ConfigStorage__factory,
  CrossMarginHandler__factory,
  ERC20__factory,
  LiquidityHandler__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";
import { getPriceData } from "../utils/pyth";
import { getUpdatePriceData } from "../utils/price";

const BigNumber = ethers.BigNumber;
const config = getConfig();
const priceUpdates = [
  1900.02, // ETH
  20000.29, // ETH
  1, // USDC
  1, // USDT
  1, // DAI
  137.3, // AAPL
  198.2, // JPY
];
const minPublishTime = Math.floor(new Date().valueOf() / 1000);
const publishTimeDiff = [
  0, // ETH
  0, // ETH
  0, // USDC
  0, // USDT
  0, // DAI
  0, // AAPL
  0, // JPY
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const liquidityHandler = LiquidityHandler__factory.connect(config.handlers.liquidity, deployer);
  const configStorage = ConfigStorage__factory.connect(config.storages.config, deployer);

  const [priceUpdateData, publishTimeDiffUpdateData] = await getUpdatePriceData(
    deployer,
    priceUpdates,
    publishTimeDiff,
    true
  );
  console.log(`Execute Liquidity Order...`);
  await (
    await liquidityHandler.executeOrder(
      ethers.constants.MaxUint256,
      deployer.address,
      priceUpdateData,
      publishTimeDiffUpdateData,
      minPublishTime,
      ethers.utils.formatBytes32String(""),
      {
        gasLimit: 200000000,
      }
    )
  ).wait();
  console.log("Execute Liquidity Order Success!");
};

export default func;
func.tags = ["ExecuteLiquidityOrder"];