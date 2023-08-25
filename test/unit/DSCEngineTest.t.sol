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
import {MockMoreDebtDSC} from "../mocks/MockMoreDebtDSC.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract DSCEngineTest is StdCheats, Test {
    /* EVENTS */
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(
        address indexed from, address indexed to, address indexed collateralAddress, uint256 amount
    );
    event CollateralLiquidated(address user);

    DeployDSC public deployer;
    DecentralisedStableCoin public dsc;
    HelperConfig config;
    DSCEngine dscEngine;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;

    address public USER = makeAddr("user-1");

    // Liquidation
    address public LIQUIDATOR = makeAddr("liquidator");
    uint256 public COLLATERAL_TO_COVER = 20 ether;

    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 AMOUNT_TO_MINT = 100 ether;

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;
    uint256 public constant LIQUIDATION_BONUS = 10; // 10%

    function setUp() external {
        deployer = new DeployDSC();

        (dsc, dscEngine, config) = deployer.run();

        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_USER_BALANCE);
        // ERC20Mock(weth).mint(LIQUIDATOR, STARTING_USER_BALANCE);
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

    modifier mintDSCToken() {
        vm.startPrank(USER);

        dscEngine.mintDsc(10000e18); // Mint 10000 DSC tokens for 10 ether worth of collateral

        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_TO_MINT);
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

    function testShouldRevertIfHealthFactorBreaksOnMintingDsc() public {
        vm.startPrank(USER);
        // Arrange
        uint256 DSC_TOKENS_TO_MINT = 1000;

        // Before
        console.log("HEALTH FACTOR: ", dscEngine.getHealthFactor(USER));

        // Should Revert
        vm.expectRevert(DSCEngine.DSCEngine__BreaksHealthFactor.selector);
        dscEngine.mintDsc(DSC_TOKENS_TO_MINT);

        // After
        console.log("HEALTH FACTOR: ", dscEngine.getHealthFactor(USER));

        vm.stopPrank();
    }

    // Health Factor
    function testProperlyReportsHealthFactor() public depositedCollateral mintDSCToken {
        vm.startPrank(USER);
        uint256 expectedHealthFactor = 1 ether; // 1e18
        uint256 actualHealthFactor = dscEngine.getHealthFactor(USER);
        // $10000 minted with $20,000 collateral at 50% liquidation threshold
        // 10,000 / 10000 = 1 health factor => 1e18
        assertEq(actualHealthFactor, expectedHealthFactor);

        vm.stopPrank();
    }

    // Burn Function
    function testShouldRevertForZeroTokenBurn() public {
        vm.startPrank(USER);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);

        dscEngine.burnDsc(0); // Try to burn zero DSC tokens

        vm.stopPrank();
    }

    function testForEmittedEventOnCollateralRedeemed() public depositedCollateral {
        vm.startPrank(USER);

        vm.expectEmit(true, true, true, false, address(dscEngine));

        emit CollateralRedeemed(USER, USER, weth, AMOUNT_COLLATERAL);

        dscEngine.redeemCollateral(weth, AMOUNT_COLLATERAL);

        vm.stopPrank();
    }

    // Liquidation Tests

    function testShouldNotAllowLiquidationIfUserHealthFactorIsGood() public depositedCollateral {
        vm.startPrank(LIQUIDATOR);

        uint256 DEBT_TO_COVER = 100; // 100 DSC Tokens

        console.log("HEALTH FACTOR: ", dscEngine.getHealthFactor(USER));

        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorIsOkay.selector);
        dscEngine.liquidate(weth, USER, DEBT_TO_COVER);

        console.log("HEALTH FACTOR: ", dscEngine.getHealthFactor(USER));

        vm.stopPrank();
    }

    function testMustImproveHealthFactorOnLiquidation() public {
        // Arrange
        MockMoreDebtDSC mockDsc = new MockMoreDebtDSC(ethUsdPriceFeed);
        tokenAddresses = [weth];
        feedAddresses = [ethUsdPriceFeed];
        address owner = msg.sender;

        vm.prank(owner);
        DSCEngine mockDsce = new DSCEngine(
            tokenAddresses,
            feedAddresses,
            address(mockDsc)
        );
        mockDsc.transferOwnership(address(mockDsce));

        // Arrange - User
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(mockDsce), AMOUNT_COLLATERAL);
        mockDsce.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_TO_MINT);
        vm.stopPrank();

        // Arrange - Liquidator
        COLLATERAL_TO_COVER = 1 ether;
        ERC20Mock(weth).mint(LIQUIDATOR, COLLATERAL_TO_COVER);

        vm.startPrank(LIQUIDATOR);

        ERC20Mock(weth).approve(address(mockDsce), COLLATERAL_TO_COVER);
        uint256 debtToCover = 10 ether;
        mockDsce.depositCollateralAndMintDsc(weth, COLLATERAL_TO_COVER, AMOUNT_TO_MINT);
        mockDsc.approve(address(mockDsce), debtToCover);

        // Act
        int256 ethUsdUpdatedPrice = 18e8; // 1 ETH = $18
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);

        // Assert
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorNotImproved.selector);
        mockDsce.liquidate(weth, USER, debtToCover);

        vm.stopPrank();
    }

    function testShouldEmitUserLiquidatedEventOnLiquidation() public {
        // Arrange
        MockMoreDebtDSC mockDsc = new MockMoreDebtDSC(ethUsdPriceFeed);
        tokenAddresses = [weth];
        feedAddresses = [ethUsdPriceFeed];
        address owner = msg.sender;

        vm.prank(owner);
        DSCEngine mockDsce = new DSCEngine(
            tokenAddresses,
            feedAddresses,
            address(mockDsc)
        );
        mockDsc.transferOwnership(address(mockDsce));

        // Arrange - User
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(mockDsce), AMOUNT_COLLATERAL);
        mockDsce.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_TO_MINT); // dsc Mint
        vm.stopPrank();

        int256 ethUsdUpdatedPrice = 18e8; // 1 ETH = $18
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);

        COLLATERAL_TO_COVER = 20 ether;
        ERC20Mock(weth).mint(LIQUIDATOR, COLLATERAL_TO_COVER);

        // Liquidator
        vm.startPrank(LIQUIDATOR);
        ERC20Mock(weth).approve(address(mockDsce), COLLATERAL_TO_COVER);
        mockDsce.depositCollateralAndMintDsc(weth, COLLATERAL_TO_COVER, AMOUNT_TO_MINT);
        mockDsc.approve(address(mockDsce), AMOUNT_TO_MINT); // covering ALL Debt of USER

        // Check for emitted event
        vm.expectEmit(true, false, false, false, address(mockDsce));
        emit CollateralLiquidated(USER);

        vm.expectRevert(DSCEngine.DSCEngine__BreaksHealthFactor.selector);
        mockDsce.liquidate(weth, USER, AMOUNT_TO_MINT);

        vm.stopPrank();
    }

    function testShouldRevertForLiquidateWithZeroDebt() public depositedCollateral {
        vm.startPrank(LIQUIDATOR);

        uint256 DEBT_TO_COVER = 0;

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);

        dscEngine.liquidate(weth, USER, DEBT_TO_COVER);

        vm.stopPrank();
    }

    function testShouldNotAllowAdditionalDSCTokenMintIfUserHealthFactorBreaks()
        public
        depositedCollateral
        mintDSCToken
    {
        vm.startPrank(USER);

        vm.expectRevert(DSCEngine.DSCEngine__BreaksHealthFactor.selector); // should revert
        dscEngine.mintDsc(1e18); // Try to Mint 1 additional DSC token which should break health factor

        vm.stopPrank();
    }

    // function testShouldRevertIfHealthFactorIsNotImproved() public depositedCollateral mintDSCToken {
    //     setHealthFactor(USER, MIN_HEALTH_FACTOR);
    //     console.log("CURRENT: ", currentHealthFactor);

    //     vm.startPrank(LIQUIDATOR);

    //     uint256 DEBT_TO_COVER = 1;

    //     vm.expectRevert(DSCEngine.DSCEngine__HealthFactorNotImproved.selector);
    //     dscEngine.liquidate(weth, USER, DEBT_TO_COVER);

    //     console.log("ENDING HEALTH FACTOR: ", dscEngine.getHealthFactor(USER));

    //     vm.stopPrank();
    // }

    // function testShouldCalculateCorrectTokenAmountFromDebtToCover() public depositedCollateral mintDSCToken {
    //     vm.startPrank(LIQUIDATOR);

    //     uint256 DEBT_TO_COVER = 1000e18;

    //     uint256 TOKEN_AMOUNT_FROM_DEBT_COVERED = 5e17;
    //     uint256 BONUS_COLLATERAL;
    //     uint256 TOKEN_COLLATERAL_TO_REDEEM;

    //     uint256 actualTokenAmount = dscEngine.getTokenAmountFromUsd(weth, DEBT_TO_COVER);

    //     // Call liquidate function
    //     dscEngine.liquidate(weth, USER, DEBT_TO_COVER);

    //     // Check calculated values
    //     BONUS_COLLATERAL = (TOKEN_AMOUNT_FROM_DEBT_COVERED * LIQUIDATION_BONUS) / 100;
    //     TOKEN_COLLATERAL_TO_REDEEM = TOKEN_AMOUNT_FROM_DEBT_COVERED + BONUS_COLLATERAL;

    //     assertEq(actualTokenAmount, TOKEN_COLLATERAL_TO_REDEEM);

    //     vm.stopPrank();
    // }
}
