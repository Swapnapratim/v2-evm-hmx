// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { BaseIntTest_SetMarkets } from "@hmx-test/integration/03_BaseIntTest_SetMarkets.i.sol";

abstract contract BaseIntTest_SetOracle is BaseIntTest_SetMarkets {
  error BadArgs();

  bytes32 constant wethPriceId = 0x0000000000000000000000000000000000000000000000000000000000000001;
  bytes32 constant wbtcPriceId = 0x0000000000000000000000000000000000000000000000000000000000000002;
  bytes32 constant usdcPriceId = 0x0000000000000000000000000000000000000000000000000000000000000003;
  bytes32 constant usdtPriceId = 0x0000000000000000000000000000000000000000000000000000000000000004;
  bytes32 constant daiPriceId = 0x0000000000000000000000000000000000000000000000000000000000000005;
  bytes32 constant applePriceId = 0x0000000000000000000000000000000000000000000000000000000000000006;
  bytes32 constant jpyPriceid = 0x0000000000000000000000000000000000000000000000000000000000000007;

  struct AssetPythPriceData {
    bytes32 assetId;
    bytes32 priceId;
    int64 price;
    int64 exponent;
    bool inverse;
  }

  AssetPythPriceData[] assetPythPriceDatas;
  /// @notice will change when a function called "setPrices" is used or when an object is created through a function called "constructor"
  bytes[] initialPriceFeedDatas;

  constructor() {
    assetPythPriceDatas.push(
      AssetPythPriceData({ assetId: wethAssetId, priceId: wethPriceId, price: 1500, exponent: -8, inverse: false })
    );
    assetPythPriceDatas.push(
      AssetPythPriceData({ assetId: wbtcAssetId, priceId: wbtcPriceId, price: 20000, exponent: -8, inverse: false })
    );
    assetPythPriceDatas.push(
      AssetPythPriceData({ assetId: daiAssetId, priceId: daiPriceId, price: 1, exponent: -8, inverse: false })
    );
    assetPythPriceDatas.push(
      AssetPythPriceData({ assetId: usdcAssetId, priceId: usdcPriceId, price: 1, exponent: -8, inverse: false })
    );
    assetPythPriceDatas.push(
      AssetPythPriceData({ assetId: usdtAssetId, priceId: usdtPriceId, price: 1, exponent: -8, inverse: false })
    );
    assetPythPriceDatas.push(
      AssetPythPriceData({ assetId: appleAssetId, priceId: applePriceId, price: 152, exponent: -5, inverse: false })
    );
    // @todo - after integrate with inverse config then price should be change to USDJPY
    assetPythPriceDatas.push(
      AssetPythPriceData({
        assetId: jpyAssetId,
        priceId: jpyPriceid,
        price: 136.123 * 1e3,
        exponent: -3,
        inverse: true
      })
    );

    // Set MarketStatus
    uint8 _marketActiveStatus = uint8(2);
    oracleMiddleWare.setUpdater(address(this), true); // Whitelist updater for oracleMiddleWare
    // crypto
    oracleMiddleWare.setMarketStatus(usdcAssetId, _marketActiveStatus); // active
    oracleMiddleWare.setMarketStatus(usdtAssetId, _marketActiveStatus); // active
    oracleMiddleWare.setMarketStatus(daiAssetId, _marketActiveStatus); // active
    oracleMiddleWare.setMarketStatus(wethAssetId, _marketActiveStatus); // active
    oracleMiddleWare.setMarketStatus(wbtcAssetId, _marketActiveStatus); // active
    // equity
    oracleMiddleWare.setMarketStatus(appleAssetId, _marketActiveStatus); // active
    // forex
    oracleMiddleWare.setMarketStatus(jpyAssetId, _marketActiveStatus); // active

    // Set AssetPriceConfig
    uint32 _confidenceThresholdE6 = 2500; // 2.5% for test only
    uint32 _trustPriceAge = type(uint32).max; // set max for test only
    oracleMiddleWare.setAssetPriceConfig(wethAssetId, _confidenceThresholdE6, _trustPriceAge);
    oracleMiddleWare.setAssetPriceConfig(wbtcAssetId, _confidenceThresholdE6, _trustPriceAge);
    oracleMiddleWare.setAssetPriceConfig(daiAssetId, _confidenceThresholdE6, _trustPriceAge);
    oracleMiddleWare.setAssetPriceConfig(usdcAssetId, _confidenceThresholdE6, _trustPriceAge);
    oracleMiddleWare.setAssetPriceConfig(usdtAssetId, _confidenceThresholdE6, _trustPriceAge);
    oracleMiddleWare.setAssetPriceConfig(appleAssetId, _confidenceThresholdE6, _trustPriceAge);
    oracleMiddleWare.setAssetPriceConfig(jpyAssetId, _confidenceThresholdE6, _trustPriceAge);

    AssetPythPriceData memory _data;
    for (uint256 i = 0; i < assetPythPriceDatas.length; ) {
      _data = assetPythPriceDatas[i];

      // set PythId
      pythAdapter.setConfig(_data.assetId, _data.priceId, _data.inverse);
      // set UpdatePriceFeed
      initialPriceFeedDatas.push(_createPriceFeedUpdateData(_data.assetId, _data.price));

      unchecked {
        ++i;
      }
    }
    uint256 fee = pyth.getUpdateFee(initialPriceFeedDatas);
    vm.deal(address(this), fee);
    pyth.updatePriceFeeds{ value: fee }(initialPriceFeedDatas);
  }

  /// @notice setPrices of pyth
  /// @param _assetIds assetIds array
  /// @param _prices price of each asset
  /// @return _newDatas bytes[] of setting
  function setPrices(bytes32[] memory _assetIds, int64[] memory _prices) public returns (bytes[] memory _newDatas) {
    if (_assetIds.length != _prices.length) {
      revert BadArgs();
    }

    _newDatas = new bytes[](_assetIds.length);

    for (uint256 i = 0; i < _assetIds.length; ) {
      _newDatas[i] = (_createPriceFeedUpdateData(_assetIds[i], _prices[i]));
      unchecked {
        ++i;
      }
    }

    uint256 fee = pyth.getUpdateFee(_newDatas);
    vm.deal(address(this), fee);
    pyth.updatePriceFeeds{ value: fee }(_newDatas);
    return _newDatas;
  }

  function _createPriceFeedUpdateData(bytes32 _assetId, int64 _price) internal returns (bytes memory) {
    int64 pythDecimals;

    for (uint256 i = 0; i < assetPythPriceDatas.length; ) {
      if (assetPythPriceDatas[i].assetId == _assetId) {
        pythDecimals = assetPythPriceDatas[i].exponent;
        break;
      }
      unchecked {
        ++i;
      }
    }

    int64 _pythDecimalPow = int64(10) ** uint64(-pythDecimals);
    (bytes32 _pythPriceId, ) = pythAdapter.configs(_assetId);
    bytes memory priceFeedData = pyth.createPriceFeedUpdateData(
      _pythPriceId,
      _price * _pythDecimalPow,
      0,
      int8(pythDecimals),
      _price * _pythDecimalPow,
      0,
      uint64(block.timestamp)
    );

    return priceFeedData;
  }
}