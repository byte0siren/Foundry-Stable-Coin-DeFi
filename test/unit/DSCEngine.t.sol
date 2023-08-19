// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

// import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";

contract DSCEngineTest is StdCheats, Test {
    /* EVENTS */
    event CollateralDeposited(address indexed USER, address indexed weth, uint256 indexed AMOUNT_COLLATERAL);

    DeployDSC deployer;
    DecentralisedStableCoin dsc;
    HelperConfig config;
    DSCEngine dscEngine;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;

    address public USER = makeAddr("user-1");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;

    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        deployer = new DeployDSC();

        (dsc, dscEngine, config) = deployer.run();

        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_USER_BALANCE);
    }

    ///////////////////////
    // Constructor Tests //
    ///////////////////////
    address[] public tokenAddresses;
    address[] public feedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        feedAddresses.push(ethUsdPriceFeed);
        feedAddresses.push(btcUsdPriceFeed);

        // console.log("TOKEN ADDRESSES LENGTH: ", tokenAddresses.length);
        // console.log("FEED ADDRESSES LENGTH: ", feedAddresses.length);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch.selector);

        new DSCEngine(tokenAddresses, feedAddresses, address(dsc));
    }

    //////////////////
    // Price Tests //
    //////////////////

    function testGetUsdValue() public {
        uint256 ethAmount = 10e18; // 10 ETH

        uint256 expectedUSD = 20000e18; // 10 ETH * 2000 USD/ETH = 20000 USD;
        uint256 actualUSD = dscEngine.getUsdValue(weth, ethAmount);

        // console.log("ACTUAL USD Value: ", actualUSD);

        assertEq(expectedUSD, actualUSD);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;

        uint256 expectedWeth = 0.05 ether; // 100 ETH / 2000 usd/eth = 0.05 weth

        uint256 actualWeth = dscEngine.getTokenAmountFromUsd(weth, usdAmount);

        assertEq(expectedWeth, actualWeth);
    }

    ///////////////////////////////////////
    // depositCollateral Tests //
    ///////////////////////////////////////

    function testShouldRevertIfCollateralIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscEngine.depositCollateral(weth, 0);

        vm.stopPrank();
    }

    function testRevertsWithNotApprovedCollateral() public {
        ERC20Mock randomToken = new ERC20Mock("RNDM", "RNDM", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);

        vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed.selector);
        dscEngine.depositCollateral(address(randomToken), AMOUNT_COLLATERAL);

        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);

        vm.stopPrank();
        _;
    }

    function testUserCanDepositCollateralAndGetAccountInformation() public depositedCollateral {
        (uint256 totalDscminted, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);

        uint256 expectedDscMinted = 0;
        uint256 expectedDepositAmount = dscEngine.getTokenAmountFromUsd(weth, collateralValueInUsd);

        assertEq(expectedDscMinted, totalDscminted);

        assertEq(expectedDepositAmount, AMOUNT_COLLATERAL);
    }

    function testForEventEmittedOnCollateralDeposit() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectEmit(true, true, true, false, address(dscEngine));

        emit CollateralDeposited(USER, weth, AMOUNT_COLLATERAL);

        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);

        vm.stopPrank();
    }

    function testRevertsIfZeroTokensMinted() public depositedCollateral {
        vm.startPrank(USER);

        uint256 DSC_TOKENS_TO_MINT = 0;

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);

        dscEngine.mintDsc(DSC_TOKENS_TO_MINT); // Should Revert

        vm.stopPrank();
    }
}
