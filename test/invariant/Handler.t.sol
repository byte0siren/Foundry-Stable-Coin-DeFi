// Handler provides a way to call our Invariant functions
// in a specific way for testing.

pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT

import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract Handler is StdInvariant, Test {
    DSCEngine dscEngine;
    DecentralisedStableCoin dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_AMOUNT_COLLATERAL_SIZE = type(uint96).max;

    constructor(DSCEngine _dscEngine, DecentralisedStableCoin _dsc) {
        dscEngine = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dscEngine.getCollateralTokens();

        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // Handler based tests provides a way to perform a specific path for fuzz tests
    function depositCollateralHandler(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralAddressFromSeedHandler(collateralSeed);

        amountCollateral = bound(amountCollateral, 1, MAX_AMOUNT_COLLATERAL_SIZE);

        vm.startPrank(msg.sender);

        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dscEngine), amountCollateral);
        dscEngine.depositCollateral(address(collateral), amountCollateral);

        vm.stopPrank();
    }

    function _getCollateralAddressFromSeedHandler(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) return weth;
        return wbtc;
    }
}
