// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;
import { TestBase } from "forge-std/Base.sol";
import { StdCheatsSafe } from "forge-std/StdCheats.sol";
import { StdAssertions } from "forge-std/StdAssertions.sol";

import { OrderReader } from "@hmx/readers/OrderReader.sol";
import { LimitTradeHandler } from "@hmx/handlers/LimitTradeHandler.sol";

//Deployer
import { Deployer } from "@hmx-test/libs/Deployer.sol";

contract OrderReader_GetExecutable is TestBase, StdAssertions, StdCheatsSafe {
  OrderReader orderReader;
  uint256 arbitrumForkId;

  function setUp() public {
    arbitrumForkId = vm.createSelectFork(vm.rpcUrl("arbitrum_fork"));

    address _configStorage = 0xF4F7123fFe42c4C90A4bCDD2317D397E0B7d7cc0;
    address _perpStorage = 0x97e94BdA44a2Df784Ab6535aaE2D62EFC6D2e303;
    address _oracleMiddleware = 0x9c83e1046dA4727F05C6764c017C6E1757596592;
    address _limitTradeHandler = 0xeE116128b9AAAdBcd1f7C18608C5114f594cf5D6;

    orderReader = Deployer.deployOrderReader(_configStorage, _perpStorage, _oracleMiddleware, _limitTradeHandler);
  }

  function testCorrectness_getExecutableOrder() external view {
    bytes32[] memory _assetIds = new bytes32[](27);
    _assetIds[0] = 0x4554480000000000000000000000000000000000000000000000000000000000;
    _assetIds[1] = 0x4254430000000000000000000000000000000000000000000000000000000000;
    _assetIds[2] = 0x5553444300000000000000000000000000000000000000000000000000000000;
    _assetIds[3] = 0x5553445400000000000000000000000000000000000000000000000000000000;
    _assetIds[4] = 0x4441490000000000000000000000000000000000000000000000000000000000;
    _assetIds[5] = 0x4141504c00000000000000000000000000000000000000000000000000000000;
    _assetIds[6] = 0x4a50590000000000000000000000000000000000000000000000000000000000;
    _assetIds[7] = 0x5841550000000000000000000000000000000000000000000000000000000000;
    _assetIds[8] = 0x414d5a4e00000000000000000000000000000000000000000000000000000000;
    _assetIds[9] = 0x4d53465400000000000000000000000000000000000000000000000000000000;
    _assetIds[10] = 0x54534c4100000000000000000000000000000000000000000000000000000000;
    _assetIds[11] = 0x4555520000000000000000000000000000000000000000000000000000000000;
    _assetIds[12] = 0x5841470000000000000000000000000000000000000000000000000000000000;
    _assetIds[13] = 0x4155440000000000000000000000000000000000000000000000000000000000;
    _assetIds[14] = 0x4742500000000000000000000000000000000000000000000000000000000000;
    _assetIds[15] = 0x4144410000000000000000000000000000000000000000000000000000000000;
    _assetIds[16] = 0x4d41544943000000000000000000000000000000000000000000000000000000;
    _assetIds[17] = 0x5355490000000000000000000000000000000000000000000000000000000000;
    _assetIds[18] = 0x4152420000000000000000000000000000000000000000000000000000000000;
    _assetIds[19] = 0x4f50000000000000000000000000000000000000000000000000000000000000;
    _assetIds[20] = 0x4c54430000000000000000000000000000000000000000000000000000000000;
    _assetIds[21] = 0x434f494e00000000000000000000000000000000000000000000000000000000;
    _assetIds[22] = 0x474f4f4700000000000000000000000000000000000000000000000000000000;
    _assetIds[23] = 0x424e420000000000000000000000000000000000000000000000000000000000;
    _assetIds[24] = 0x534f4c0000000000000000000000000000000000000000000000000000000000;
    _assetIds[25] = 0x5151510000000000000000000000000000000000000000000000000000000000;
    _assetIds[26] = 0x5852500000000000000000000000000000000000000000000000000000000000;
    uint64[] memory _prices = new uint64[](27);
    _prices[0] = 190644000000;
    _prices[1] = 3015234793923;
    _prices[2] = 99998500;
    _prices[3] = 100008392;
    _prices[4] = 99994250;
    _prices[5] = 19489298999;
    _prices[6] = 716594;
    _prices[7] = 198135500000;
    _prices[8] = 13497000000;
    _prices[9] = 35474620000;
    _prices[10] = 29250500000;
    _prices[11] = 112102000;
    _prices[12] = 2512399000;
    _prices[13] = 68187999;
    _prices[14] = 129227999;
    _prices[15] = 32855000;
    _prices[16] = 76785010;
    _prices[17] = 71777474;
    _prices[18] = 127446373;
    _prices[19] = 155963306;
    _prices[20] = 9276300800;
    _prices[21] = 11013999999;
    _prices[22] = 12310000000;
    _prices[23] = 24287048160;
    _prices[24] = 2686065000;
    _prices[25] = 38539500000;
    _prices[26] = 83303304;

    orderReader.getExecutableOrders(100, 0, _assetIds, _prices);
  }
}