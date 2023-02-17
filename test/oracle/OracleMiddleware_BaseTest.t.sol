// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { BaseTest } from "../base/BaseTest.sol";
import { OracleMiddleware } from "../../src/oracle/OracleMiddleware.sol";
import { AddressUtils } from "../../src/libraries/AddressUtils.sol";

contract OracleMiddleware_BaseTest is BaseTest {
  using AddressUtils for address;
  OracleMiddleware oracleMiddleware;

  function setUp() public virtual {
    DeployReturnVars memory deployed = deployPerp88v2();
    oracleMiddleware = deployed.oracleMiddleware;

    vm.deal(ALICE, 1 ether);

    // Feed wbtc
    {
      deployed.pythAdapter.setUpdater(ALICE, true);
      deployed.pythAdapter.setPythPriceId(
        address(wbtc).toBytes32(),
        wbtcPriceId
      );

      bytes[] memory priceDataBytes = new bytes[](1);
      priceDataBytes[0] = mockPyth.createPriceFeedUpdateData(
        wbtcPriceId,
        20_000 * 1e8,
        500 * 1e8,
        -8,
        20_000 * 1e8,
        500 * 1e8,
        uint64(block.timestamp)
      );

      vm.startPrank(ALICE);
      deployed.pythAdapter.updatePrices{
        value: deployed.pythAdapter.getUpdateFee(priceDataBytes)
      }(priceDataBytes);
      vm.stopPrank();
    }
  }
}