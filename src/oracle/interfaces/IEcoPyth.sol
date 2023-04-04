// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { PythStructs } from "pyth-sdk-solidity/IPyth.sol";

interface IEcoPyth {
  function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

  function updatePriceFeeds(
    bytes32[] calldata _priceIds,
    uint256[] calldata _packedPriceDatas,
    bytes32 _encodedVaas
  ) external;
}
