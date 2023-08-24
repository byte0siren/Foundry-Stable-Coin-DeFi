// SPDX-License-Identifier: MIT

// Invariants: Properties of the system / protocol which should always HOLD.

// Invariants:
// Defi Stablecoin protocol must never be insolvent / undercollateralized

pragma solidity 0.8.13;

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Handler} from "./Handler.t.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dscEngine;
    DecentralisedStableCoin dsc;
    HelperConfig helperConfig;
    Handler handler;
    address weth;
    address wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (,, weth, wbtc,) = helperConfig.activeNetworkConfig();

        // Targets Handler -> Handler Contract
        handler = new Handler(dscEngine, dsc);
        targetContract(address(handler));
        // targetContract(address(dscEngine));
    }

    function invariant_protocolMustHaveMoreCollateralValueThanTotalSupply() public view {
        uint256 totalDSCSupply = dsc.totalSupply();

        uint256 totalWETHDeposited = IERC20(weth).balanceOf(address(dscEngine));
        uint256 totalWBTCDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

        uint256 wethValue = dscEngine.getUsdValue(weth, totalWETHDeposited);
        uint256 wbtcValue = dscEngine.getUsdValue(wbtc, totalWBTCDeposited);

        console.log("WETH Value: ", wethValue);
        console.log("WBTC Value: ", wbtcValue);
        console.log("TOTAL Supply: ", totalDSCSupply);

        assert(wethValue + wbtcValue >= totalDSCSupply);
    }
}
