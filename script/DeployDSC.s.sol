// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {DecentralisedStableCoin} from "../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";

contract DeployDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddressesInUSD;

    function run() external returns (DecentralisedStableCoin, DSCEngine, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            config.activeNetworkConfig();

        tokenAddresses = [weth, wbtc];
        priceFeedAddressesInUSD = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);

        DecentralisedStableCoin dsc = new DecentralisedStableCoin();
        DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddressesInUSD, address(dsc));

        dsc.transferOwnership(address(dscEngine)); // DSCEngine Owns DSC ERC20 Token contract

        vm.stopBroadcast();

        return (dsc, dscEngine, config);
    }
}
