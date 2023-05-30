// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Forge-std
import { TestBase } from "forge-std/Base.sol";
import { console } from "forge-std/console.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

// Pyth
import { IPyth } from "pyth-sdk-solidity/IPyth.sol";
import { MockPyth } from "pyth-sdk-solidity/MockPyth.sol";
import { EcoPyth } from "@hmx/oracles/EcoPyth.sol";
import { IEcoPyth } from "@hmx/oracles/interfaces/IEcoPyth.sol";

// Openzeppelin
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20Upgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
// Libs
import { Deployer } from "@hmx-test/libs/Deployer.sol";

// Mock
import { MockWNative } from "@hmx-test/mocks/MockWNative.sol";
import { MockErc20 } from "@hmx-test/mocks/MockErc20.sol";
import { MockGmxRewardRouterV2 } from "@hmx-test/mocks/MockGmxRewardRouterV2.sol";

// Interfaces
import { IWNative } from "@hmx/interfaces/IWNative.sol";

import { IPLPv2 } from "@hmx/contracts/interfaces/IPLPv2.sol";
import { ICalculator } from "@hmx/contracts/interfaces/ICalculator.sol";
import { IOracleAdapter } from "@hmx/oracles/interfaces/IOracleAdapter.sol";
import { IOracleMiddleware } from "@hmx/oracles/interfaces/IOracleMiddleware.sol";

import { IConfigStorage } from "@hmx/storages/interfaces/IConfigStorage.sol";
import { IPerpStorage } from "@hmx/storages/interfaces/IPerpStorage.sol";
import { IVaultStorage } from "@hmx/storages/interfaces/IVaultStorage.sol";
import { IPLPv2 } from "@hmx/contracts/interfaces/IPLPv2.sol";
import { IPythAdapter } from "@hmx/oracles/interfaces/IPythAdapter.sol";

import { IBotHandler } from "@hmx/handlers/interfaces/IBotHandler.sol";
import { ICrossMarginHandler } from "@hmx/handlers/interfaces/ICrossMarginHandler.sol";
import { ILimitTradeHandler } from "@hmx/handlers/interfaces/ILimitTradeHandler.sol";
import { ILiquidityHandler } from "@hmx/handlers/interfaces/ILiquidityHandler.sol";
import { IMarketTradeHandler } from "@hmx/handlers/interfaces/IMarketTradeHandler.sol";

import { ConvertedGlpStrategy } from "@hmx/strategies/ConvertedGlpStrategy.sol";
import { IConvertedGlpStrategy } from "@hmx/strategies/interfaces/IConvertedGlpStrategy.sol";

import { ICrossMarginService } from "@hmx/services/interfaces/ICrossMarginService.sol";
import { ILiquidityService } from "@hmx/services/interfaces/ILiquidityService.sol";
import { ILiquidationService } from "@hmx/services/interfaces/ILiquidationService.sol";
import { ITradeService } from "@hmx/services/interfaces/ITradeService.sol";

import { IGmxRewardRouterV2 } from "@hmx/interfaces/gmx/IGmxRewardRouterV2.sol";

import { ITradeHelper } from "@hmx/helpers/interfaces/ITradeHelper.sol";

import { IPyth } from "pyth-sdk-solidity/IPyth.sol";
import { LiquidityTester } from "@hmx-test/testers/LiquidityTester.sol";
import { CrossMarginTester } from "@hmx-test/testers/CrossMarginTester.sol";
import { LimitOrderTester } from "@hmx-test/testers/LimitOrderTester.sol";
import { PositionTester } from "@hmx-test/testers/PositionTester.sol";
import { MarketTester } from "@hmx-test/testers/MarketTester.sol";
import { PositionTester02 } from "@hmx-test/testers/PositionTester02.sol";
import { TradeTester } from "@hmx-test/testers/TradeTester.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract BaseIntTest is TestBase, StdCheats {
  /* Constants */
  uint256 internal constant executionOrderFee = 0.0001 ether;
  uint256 internal constant minExecutionTimestamp = 60 * 5; // 5 minutes

  uint256 internal constant SECONDS = 1;
  uint256 internal constant MINUTES = SECONDS * 60;
  uint256 internal constant HOURS = MINUTES * 60;
  uint256 internal constant DAYS = HOURS * 24;

  address internal ALICE;
  address internal BOB;
  address internal CAROL;
  address internal DAVE;
  address internal EVE;
  address internal FEEVER;
  address internal ORDER_EXECUTOR;
  address internal BOT;

  /* CONTRACTS */
  IOracleMiddleware oracleMiddleWare;
  IConfigStorage configStorage;
  IPerpStorage perpStorage;
  IVaultStorage vaultStorage;
  ICalculator calculator;

  // handlers
  IBotHandler botHandler;
  ICrossMarginHandler crossMarginHandler;
  ILimitTradeHandler limitTradeHandler;
  ILiquidityHandler liquidityHandler;
  IMarketTradeHandler marketTradeHandler;

  // services
  ICrossMarginService crossMarginService;
  ILiquidityService liquidityService;
  ILiquidationService liquidationService;
  ITradeService tradeService;

  //GMX
  IGmxRewardRouterV2 gmxRewardRouterV2;

  //strategies
  IConvertedGlpStrategy convertedGlpStrategy;

  // helpers
  ITradeHelper tradeHelper;

  /* TOKENS */

  //LP tokens
  ERC20Upgradeable glp;
  IPLPv2 plpV2;

  MockErc20 wbtc; // decimals 8
  MockErc20 usdc; // decimals 6
  MockErc20 usdt; // decimals 6
  MockErc20 dai; // decimals 18
  MockErc20 sglp; //decimals 18

  IWNative weth; //for native

  /* PYTH */
  IEcoPyth internal pyth;
  IPythAdapter internal pythAdapter;

  /* Tester */

  CrossMarginTester crossMarginTester;
  MarketTester globalMarketTester;
  LimitOrderTester limitOrderTester;
  LiquidityTester liquidityTester;
  PositionTester positionTester;
  PositionTester02 positionTester02;
  TradeTester tradeTester;

  ProxyAdmin proxyAdmin;

  constructor() {
    ALICE = makeAddr("Alice");
    BOB = makeAddr("BOB");
    CAROL = makeAddr("CAROL");
    DAVE = makeAddr("DAVE");
    EVE = makeAddr("EVE");
    FEEVER = makeAddr("FEEVER");
    ORDER_EXECUTOR = makeAddr("ORDER_EXECUTOR");
    BOT = makeAddr("BOT");

    /* DEPLOY PART */

    proxyAdmin = new ProxyAdmin();

    // deploy MOCK weth
    weth = IWNative(new MockWNative());
    vm.label(address(weth), "WETH");

    pyth = Deployer.deployEcoPyth(address(proxyAdmin));

    gmxRewardRouterV2 = new MockGmxRewardRouterV2();
    pythAdapter = Deployer.deployPythAdapter(address(proxyAdmin), address(pyth));

    // deploy oracleMiddleWare
    oracleMiddleWare = Deployer.deployOracleMiddleware(address(proxyAdmin), address(pyth));

    // deploy configStorage
    configStorage = Deployer.deployConfigStorage(address(proxyAdmin));

    // deploy perpStorage
    perpStorage = Deployer.deployPerpStorage(address(proxyAdmin));

    // deploy vaultStorage
    vaultStorage = Deployer.deployVaultStorage(address(proxyAdmin));

    // Tokens
    // deploy plp
    plpV2 = Deployer.deployPLPv2(address(proxyAdmin));

    wbtc = new MockErc20("Wrapped Bitcoin", "WBTC", 8);
    dai = new MockErc20("DAI Stablecoin", "DAI", 18);
    usdc = new MockErc20("USD Coin", "USDC", 6);
    usdt = new MockErc20("USD Tether", "USDT", 6);
    sglp = new MockErc20("StakedGlp", "sGLP", 18);

    // labels
    vm.label(address(wbtc), "WBTC");
    vm.label(address(dai), "DAI");
    vm.label(address(usdc), "USDC");
    vm.label(address(usdt), "USDT");
    vm.label(address(sglp), "SGLP");

    // deploy calculator
    calculator = Deployer.deployCalculator(
      address(proxyAdmin),
      address(oracleMiddleWare),
      address(vaultStorage),
      address(perpStorage),
      address(configStorage)
    );

    // deploy handler and service
    tradeHelper = Deployer.deployTradeHelper(
      address(proxyAdmin),
      address(perpStorage),
      address(vaultStorage),
      address(configStorage)
    );

    // deploy Strategies
    convertedGlpStrategy = Deployer.deployConvertedGlpStrategy(
      address(proxyAdmin),
      IERC20Upgradeable(address(sglp)),
      IGmxRewardRouterV2(gmxRewardRouterV2),
      IVaultStorage(vaultStorage)
    );

    // deploy Services
    liquidityService = Deployer.deployLiquidityService(
      address(proxyAdmin),
      address(perpStorage),
      address(vaultStorage),
      address(configStorage)
    );
    liquidationService = Deployer.deployLiquidationService(
      address(proxyAdmin),
      address(perpStorage),
      address(vaultStorage),
      address(configStorage),
      address(tradeHelper)
    );
    crossMarginService = Deployer.deployCrossMarginService(
      address(proxyAdmin),
      address(configStorage),
      address(vaultStorage),
      address(perpStorage),
      address(calculator),
      address(convertedGlpStrategy)
    );
    tradeService = Deployer.deployTradeService(
      address(proxyAdmin),
      address(perpStorage),
      address(vaultStorage),
      address(configStorage),
      address(tradeHelper)
    );

    botHandler = Deployer.deployBotHandler(
      address(proxyAdmin),
      address(tradeService),
      address(liquidationService),
      address(crossMarginService),
      address(pyth)
    );
    crossMarginHandler = Deployer.deployCrossMarginHandler(
      address(proxyAdmin),
      address(crossMarginService),
      address(pyth),
      executionOrderFee
    );

    limitTradeHandler = Deployer.deployLimitTradeHandler(
      address(proxyAdmin),
      address(weth),
      address(tradeService),
      address(pyth),
      executionOrderFee,
      minExecutionTimestamp
    );
    limitTradeHandler.setGuaranteeLimitPrice(true);

    liquidityHandler = Deployer.deployLiquidityHandler(
      address(proxyAdmin),
      address(liquidityService),
      address(pyth),
      executionOrderFee
    );

    marketTradeHandler = Deployer.deployMarketTradeHandler(address(proxyAdmin), address(tradeService), address(pyth));

    // testers

    crossMarginTester = new CrossMarginTester(vaultStorage, perpStorage, address(crossMarginHandler));
    globalMarketTester = new MarketTester(perpStorage);
    limitOrderTester = new LimitOrderTester(limitTradeHandler);
    liquidityTester = new LiquidityTester(plpV2, vaultStorage, perpStorage, FEEVER);
    positionTester = new PositionTester(perpStorage, vaultStorage, oracleMiddleWare);
    positionTester02 = new PositionTester02(perpStorage);

    address[] memory interestTokens = new address[](1);
    interestTokens[0] = address(0);
    tradeTester = new TradeTester(
      vaultStorage,
      perpStorage,
      address(limitTradeHandler),
      address(marketTradeHandler),
      interestTokens
    );
    /* Setup part */
    // Setup ConfigStorage
    {
      configStorage.setOracle(address(oracleMiddleWare));
      configStorage.setCalculator(address(calculator));

      // Set whitelists for executors
      configStorage.setServiceExecutor(address(crossMarginService), address(crossMarginHandler), true);
      configStorage.setServiceExecutor(address(crossMarginService), address(botHandler), true);
      configStorage.setServiceExecutor(address(tradeService), address(marketTradeHandler), true);
      configStorage.setServiceExecutor(address(tradeHelper), address(liquidationService), true);
      configStorage.setServiceExecutor(address(tradeHelper), address(tradeService), true);

      configStorage.setWeth(address(weth));
      configStorage.setPLP(address(plpV2));

      configStorage.setConfigExecutor(address(botHandler), true);
    }

    {
      // Reload config after calculator was set on ConfigStorage
      tradeHelper.reloadConfig();
      tradeService.reloadConfig();
      liquidationService.reloadConfig();
    }

    // Setup VaultStorage
    {
      vaultStorage.setServiceExecutors(address(crossMarginService), true);
      vaultStorage.setServiceExecutors(address(tradeService), true);
      vaultStorage.setServiceExecutors(address(tradeHelper), true);
      vaultStorage.setServiceExecutors(address(liquidityService), true);
      vaultStorage.setServiceExecutors(address(liquidationService), true);
      vaultStorage.setServiceExecutors(address(botHandler), true);
    }

    // Setup PerpStorage
    {
      perpStorage.setServiceExecutors(address(crossMarginService), true);
      perpStorage.setServiceExecutors(address(tradeService), true);
      perpStorage.setServiceExecutors(address(tradeHelper), true);
      perpStorage.setServiceExecutors(address(liquidityService), true);
      perpStorage.setServiceExecutors(address(liquidationService), true);
    }

    // Setup Bot Handler
    {
      address[] memory _positionManagers = new address[](2);
      _positionManagers[0] = address(this);
      _positionManagers[1] = BOT;

      // set Tester as position managers
      botHandler.setPositionManagers(_positionManagers, true);
    }

    // Setup Limit Trade Handler
    {
      limitTradeHandler.setOrderExecutor(address(this), true);
    }

    // Setup Cross Margin Handler
    {
      crossMarginHandler.setOrderExecutor(address(this), true);
    }
  }
}
