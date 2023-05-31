import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { CrossMarginHandler__factory, ERC20__factory, LiquidityHandler__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const BigNumber = ethers.BigNumber;
const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const liquidityHandler = LiquidityHandler__factory.connect(config.handlers.liquidity, deployer);
  const token = ERC20__factory.connect(config.tokens.usdc, deployer);
  const decimals = await token.decimals();
  const allowance = await token.allowance(deployer.address, liquidityHandler.address);
  if (allowance.eq(0)) await (await token.approve(liquidityHandler.address, ethers.constants.MaxUint256)).wait();

  const executionFee = await liquidityHandler.minExecutionOrderFee();
  console.log(`Execution Fee: ${executionFee}`);
  console.log(`Creating Add Liquidity Order...`);
  await (
    await liquidityHandler.createAddLiquidityOrder(
      token.address,
      ethers.utils.parseUnits("100", decimals),
      0,
      executionFee,
      false, //eth = true
      { value: executionFee, gasLimit: 30000000 }
    )
  ).wait();
  console.log("Create Add Liquidity Order Success!");
};

export default func;
func.tags = ["AddLiquidity"];
