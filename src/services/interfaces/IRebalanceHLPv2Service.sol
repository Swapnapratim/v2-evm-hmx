// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IGmxExchangeRouter } from "@hmx/interfaces/gmx-v2/IGmxExchangeRouter.sol";

interface IRebalanceHLPv2Service {
  error IRebalanceHLPv2Service_AmountIsZero();
  error IRebalanceHLPv2Service_BadPullAmount();
  error IRebalanceHLPv2Service_KeyNotFound();
  error IRebalanceHLPv2Service_Unauthorized();
  error IRebalanceHLPv2Service_ZeroGmReceived();

  struct DepositParams {
    address market;
    address longToken;
    uint256 longTokenAmount;
    address shortToken;
    uint256 shortTokenAmount;
    uint256 minMarketTokens;
    uint256 gasLimit;
  }

  function createDepositOrders(
    DepositParams[] calldata _depositParams,
    uint256 _executionFee
  ) external returns (bytes32[] memory gmxOrderKeys);

  function setMinHLPValueLossBPS(uint16 _hlpValueLossBPS) external;
}
