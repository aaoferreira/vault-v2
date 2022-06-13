// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "./utils/Test.sol";
import "./utils/TestConstants.sol";
import "./utils/Mocks.sol";

import "../witch/WitchV2.sol";
import "../witch/IWitchV2.sol";

abstract contract WitchV2StateZero is Test, TestConstants {
    using Mocks for *;

    event Auctioned(bytes12 indexed vaultId, uint256 indexed start);
    event Cancelled(bytes12 indexed vaultId);
    event Bought(
        bytes12 indexed vaultId,
        address indexed buyer,
        uint256 ink,
        uint256 art
    );
    event LineSet(
        bytes6 indexed ilkId,
        bytes6 indexed baseId,
        uint32 duration,
        uint64 proportion,
        uint64 initialOffer
    );
    event LimitSet(bytes6 indexed ilkId, bytes6 indexed baseId, uint128 max);
    event Point(bytes32 indexed param, address indexed value);

    bytes12 internal constant VAULT_ID = "vault";
    bytes6 internal constant ILK_ID = ETH;
    bytes6 internal constant BASE_ID = USDC;
    bytes6 internal constant SERIES_ID = FYETH2206;
    uint32 internal constant AUCTION_DURATION = 1 hours;

    // address internal admin;
    address internal deployer = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address internal ada = address(0xada);
    address internal bob = address(0xb0b);
    address internal bot = address(0xb07);
    address internal bad = address(0xbad);
    address internal cool = address(0xc001);

    ICauldron internal cauldron;
    ILadle internal ladle;

    WitchV2 internal witch;
    IWitchV2 internal iWitch;

    function setUp() public virtual {
        cauldron = ICauldron(Mocks.mock("Cauldron"));
        ladle = ILadle(Mocks.mock("Ladle"));

        vm.startPrank(ada);
        witch = new WitchV2(cauldron, ladle);
        witch.grantRole(WitchV2.point.selector, ada);
        witch.grantRole(WitchV2.setLine.selector, ada);
        witch.grantRole(WitchV2.setLimit.selector, ada);
        vm.stopPrank();

        vm.label(ada, "ada");
        vm.label(bob, "bob");

        iWitch = IWitchV2(address(witch));
    }
}

contract WitchV2StateZeroTest is WitchV2StateZero {
    function testPointRequiresAuth() public {
        vm.prank(bob);
        vm.expectRevert("Access denied");
        witch.point("ladle", bad);
    }

    function testPointRequiresLadle() public {
        vm.prank(ada);
        vm.expectRevert("Unrecognized");
        witch.point("cauldron", bad);
    }

    function testPoint() public {
        vm.expectEmit(true, true, false, true);
        emit Point("ladle", cool);

        vm.prank(ada);
        witch.point("ladle", cool);

        assertEq(address(witch.ladle()), cool);
    }

    function testSetLineRequiresAuth() public {
        vm.prank(bob);
        vm.expectRevert("Access denied");
        witch.setLine("", "", 0, 0, 0);
    }

    function testSetLineRequiresInitialOfferTooHigh() public {
        vm.prank(ada);
        vm.expectRevert("InitialOffer above 100%");
        witch.setLine("", "", 0, 0, 1e18 + 1);
    }

    function testSetLineRequiresProportionTooHigh() public {
        vm.prank(ada);
        vm.expectRevert("Proportion above 100%");
        witch.setLine("", "", 0, 1e18 + 1, 0);
    }

    function testSetLineRequiresInitialOfferTooLow() public {
        vm.prank(ada);
        vm.expectRevert("InitialOffer below 1%");
        witch.setLine("", "", 0, 0, 0.01e18 - 1);
    }

    function testSetLineRequiresProportionTooLow() public {
        vm.prank(ada);
        vm.expectRevert("Proportion below 1%");
        witch.setLine("", "", 0, 0.01e18 - 1, 0);
    }

    function testSetLine() public {
        uint64 proportion = 0.5e18;
        uint64 initialOffer = 0.75e18;

        vm.expectEmit(true, true, false, true);
        emit LineSet(
            ILK_ID,
            BASE_ID,
            AUCTION_DURATION,
            proportion,
            initialOffer
        );

        vm.prank(ada);
        witch.setLine(
            ILK_ID,
            BASE_ID,
            AUCTION_DURATION,
            proportion,
            initialOffer
        );

        (uint32 _duration, uint64 _proportion, uint64 _initialOffer) = witch
            .lines(ILK_ID, BASE_ID);

        assertEq(_duration, AUCTION_DURATION);
        assertEq(_proportion, proportion);
        assertEq(_initialOffer, initialOffer);
    }

    function testSetLimitRequiresAuth() public {
        vm.prank(bob);
        vm.expectRevert("Access denied");
        witch.setLimit("", "", 0);
    }

    function testSetLimit() public {
        uint96 max = 1;

        vm.expectEmit(true, true, false, true);
        emit LimitSet(ILK_ID, BASE_ID, max);

        vm.prank(ada);
        witch.setLimit(ILK_ID, BASE_ID, max);

        (uint128 _max, uint128 _sum) = witch.limits(ILK_ID, BASE_ID);

        assertEq(_max, max);
        assertEq(_sum, 0);
    }
}

abstract contract WitchV2WithMetadata is WitchV2StateZero {
    using Mocks for *;

    DataTypes.Vault vault;
    DataTypes.Series series;
    DataTypes.Balances balances;
    DataTypes.Debt debt;

    uint96 max = 100e18;
    uint24 dust = 5000;
    uint8 dec = 6;

    uint64 proportion = 0.5e18;
    uint64 initialOffer = 0.714e18;

    function setUp() public virtual override {
        super.setUp();

        vault = DataTypes.Vault({
            owner: bob,
            seriesId: SERIES_ID,
            ilkId: ILK_ID
        });

        series = DataTypes.Series({
            fyToken: IFYToken(Mocks.mock("FYToken")),
            baseId: BASE_ID,
            maturity: uint32(block.timestamp + 30 days)
        });

        balances = DataTypes.Balances({art: 100_000e6, ink: 100 ether});

        debt = DataTypes.Debt({
            max: 0, // Not used by the Witch
            min: dust, // Witch uses the cauldron min debt as dust
            dec: dec,
            sum: 0 // Not used by the Witch
        });

        cauldron.vaults.mock(VAULT_ID, vault);
        cauldron.series.mock(SERIES_ID, series);
        cauldron.balances.mock(VAULT_ID, balances);
        cauldron.debt.mock(BASE_ID, ILK_ID, debt);

        vm.startPrank(ada);
        witch.setLimit(ILK_ID, BASE_ID, max);
        witch.setLine(
            ILK_ID,
            BASE_ID,
            AUCTION_DURATION,
            proportion,
            initialOffer
        );
        vm.stopPrank();
    }
}

contract WitchV2WithMetadataTest is WitchV2WithMetadata {
    using Mocks for *;

    function testCalcPayout() public {
        // 100 * 0.5 * 0.714 = 35.7
        // (ink * proportion * initialOffer)
        assertEq(witch.calcPayout(VAULT_ID, 50_000e6), 35.7 ether);

        skip(5 minutes);
        // Nothing changes as auction was never started
        assertEq(witch.calcPayout(VAULT_ID, 50_000e6), 35.7 ether);
    }

    function testCalcPayoutFuzzInitialOffer(uint64 io) public {
        vm.assume(io <= 1e18 && io >= 0.01e18);

        vm.prank(ada);
        witch.setLine(ILK_ID, BASE_ID, AUCTION_DURATION, proportion, io);

        uint256 inkOut = witch.calcPayout(VAULT_ID, 50_000e6);

        assertLe(inkOut, 50 ether);
        assertGe(inkOut, 0.5 ether);
    }

    function testCalcPayoutFuzzElapsed(uint16 elapsed) public {
        skip(elapsed);

        uint256 inkOut = witch.calcPayout(VAULT_ID, 50_000e6);

        assertLe(inkOut, 50 ether);
    }

    function testVaultNotUndercollateralised() public {
        cauldron.level.mock(VAULT_ID, 0);
        vm.expectRevert("Not undercollateralized");
        witch.auction(VAULT_ID);
    }

    function testCanAuctionVault() public {
        cauldron.level.mock(VAULT_ID, -1);
        cauldron.give.mock(VAULT_ID, address(witch), vault);
        cauldron.give.verify(VAULT_ID, address(witch));

        vm.expectEmit(true, true, true, true);
        emit Auctioned(VAULT_ID, uint32(block.timestamp));

        WitchDataTypes.Auction memory auction = witch.auction(VAULT_ID);

        assertEq(auction.owner, vault.owner);
        assertEq(auction.start, uint32(block.timestamp));
        assertEq(auction.baseId, series.baseId);
        // 100,000 / 2
        assertEq(auction.art, 50_000e6);
        // 100 * 0.5
        assertEq(auction.ink, 50 ether);

        WitchDataTypes.Auction memory auction_ = iWitch.auctions(VAULT_ID);
        assertEq(auction_.owner, auction.owner);
        assertEq(auction_.start, auction.start);
        assertEq(auction_.baseId, auction.baseId);
        assertEq(auction_.art, auction.art);
        assertEq(auction_.ink, auction.ink);

        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, 50 ether);
    }

    function testCancelNonExistentAuction() public {
        vm.expectRevert("Vault not under auction");
        witch.cancel(VAULT_ID);
    }

    function testPayBaseNonExistingAuction() public {
        vm.expectRevert("Vault not under auction");
        witch.payBase(VAULT_ID, address(0), 0, 0);
    }

    function testPayFYTokenNonExistingAuction() public {
        vm.expectRevert("Vault not under auction");
        witch.payFYToken(VAULT_ID, address(0), 0, 0);
    }
}

contract WitchV2WithAuction is WitchV2WithMetadata {
    using Mocks for *;
    using WMul for uint256;
    using WMul for uint128;

    bytes12 internal constant VAULT_ID_2 = "vault2";
    WitchDataTypes.Auction auction;

    function setUp() public virtual override {
        super.setUp();

        cauldron.level.mock(VAULT_ID, -1);
        cauldron.give.mock(VAULT_ID, address(witch), vault);
        auction = witch.auction(VAULT_ID);
    }

    struct StubVault {
        bytes12 vaultId;
        uint128 ink;
        uint128 art;
        int256 level;
    }

    function _stubVault(StubVault memory params) internal {
        DataTypes.Vault memory v = DataTypes.Vault({
            owner: bob,
            seriesId: SERIES_ID,
            ilkId: ILK_ID
        });
        DataTypes.Balances memory b = DataTypes.Balances(
            params.art,
            params.ink
        );
        cauldron.vaults.mock(params.vaultId, v);
        cauldron.balances.mock(params.vaultId, b);
        cauldron.level.mock(params.vaultId, params.level);
        cauldron.give.mock(params.vaultId, address(witch), v);
    }

    function testCalcPayoutAfterAuction() public {
        // 100 * 0.5 * 0.714 = 35.7
        // (ink * proportion * initialOffer)
        assertEq(witch.calcPayout(VAULT_ID, 50_000e6), 35.7 ether);

        skip(5 minutes);
        // 100 * 0.5 * (0.714 + (1 - 0.714) * 300/3600) = 36.8916666667
        // (ink * proportion * (initialOffer + (1 - initialOffer) * timeElapsed)
        assertEq(
            witch.calcPayout(VAULT_ID, 50_000e6),
            36.89166666666666665 ether
        );

        skip(25 minutes);
        // 100 * 0.5 * (0.714 + (1 - 0.714) * 1800/3600) = 42.85
        // (ink * proportion * (initialOffer + (1 - initialOffer) * timeElapsed)
        assertEq(witch.calcPayout(VAULT_ID, 50_000e6), 42.85 ether);

        // Right at auction end
        skip(30 minutes);
        // 100 * 0.5 = 50
        // (ink * proportion)
        assertEq(witch.calcPayout(VAULT_ID, 50_000e6), 50 ether);

        // After the auction ends the value is fixed
        skip(1 hours);
        assertEq(witch.calcPayout(VAULT_ID, 50_000e6), 50 ether);
    }

    function testAuctionAlreadyExists() public {
        vm.expectRevert("Vault already under auction");
        witch.auction(VAULT_ID);
    }

    function testCollateralLimits() public {
        // Given
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, 50 ether);

        _stubVault(
            StubVault({
                vaultId: VAULT_ID_2,
                ink: 101 ether,
                art: 100_000e6,
                level: -1
            })
        );

        // When
        witch.auction(VAULT_ID_2);

        // Then
        (, sum) = witch.limits(ILK_ID, BASE_ID);
        // Max is 100, but the position could be auctioned due to the soft limit
        // Next position will fail
        assertEq(sum, 100.5 ether);

        // Given
        bytes12 otherVaultId = "other vault";
        _stubVault(
            StubVault({
                vaultId: otherVaultId,
                ink: 10 ether,
                art: 20_000e6,
                level: -1
            })
        );

        // Expect
        vm.expectRevert("Collateral limit reached");

        // When
        witch.auction(otherVaultId);
    }

    function testDustLimit() public {
        // Half of this vault would be less than the min of 5k
        _stubVault(
            StubVault({
                vaultId: VAULT_ID_2,
                ink: 5 ether,
                art: 9999e6,
                level: -1
            })
        );

        WitchDataTypes.Auction memory auction2 = witch.auction(VAULT_ID_2);

        assertEq(auction2.owner, vault.owner);
        assertEq(auction2.start, uint32(block.timestamp));
        assertEq(auction2.baseId, series.baseId);
        // 100% of the vault was put for liquidation
        assertEq(auction2.art, 9999e6);
        assertEq(auction2.ink, 5 ether);
    }

    function testUpdateLimit() public {
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, 50 ether);

        vm.prank(ada);
        witch.setLimit(ILK_ID, BASE_ID, 1);

        (uint128 _max, uint128 _sum) = witch.limits(ILK_ID, BASE_ID);

        assertEq(_max, 1);
        // Sum is copied from old values
        assertEq(_sum, 50 ether);
    }

    function testCancelUndercollateralisedAuction() public {
        vm.expectRevert("Undercollateralized");
        witch.cancel(VAULT_ID);
    }

    function testCancelAuction() public {
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, 50 ether);

        cauldron.level.mock(VAULT_ID, 0);
        cauldron.give.mock(VAULT_ID, bob, vault);
        cauldron.give.verify(VAULT_ID, bob);

        vm.expectEmit(true, true, true, true);
        emit Cancelled(VAULT_ID);

        witch.cancel(VAULT_ID);

        // sum is reduced by the auction.ink
        (, sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, 0);

        _auctionWasDeleted(VAULT_ID);
    }

    function testPayBaseNotEnoughBought() public {
        // Bot tries to get all collateral but auction just started
        uint128 minInkOut = 50 ether;
        uint128 maxBaseIn = 50_000e6;

        // make fyToken 1:1 with base to make things simpler
        cauldron.debtFromBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);
        cauldron.debtToBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);

        vm.expectRevert("Not enough bought");
        witch.payBase(VAULT_ID, bot, minInkOut, maxBaseIn);
    }

    function testPayBaseLeavesDust() public {
        // Bot tries to pay an amount that'd leaves dust
        uint128 maxBaseIn = auction.art - 4999e6;

        // make fyToken 1:1 with base to make things simpler
        cauldron.debtFromBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);
        cauldron.debtToBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);

        vm.expectRevert("Leaves dust");
        witch.payBase(VAULT_ID, bot, 0, maxBaseIn);
    }

    function testPayBasePartial() public {
        // Bot Will pay 40% of the debt (for some reason)
        uint128 maxBaseIn = uint128(auction.art.wmul(0.4e18));
        uint128 minInkOut = uint128(witch.calcPayout(VAULT_ID, maxBaseIn));

        // Reduce balances on tha vault
        cauldron.slurp.mock(VAULT_ID, minInkOut, maxBaseIn, balances);
        cauldron.slurp.verify(VAULT_ID, minInkOut, maxBaseIn);

        // make fyToken 1:1 with base to make things simpler
        cauldron.debtFromBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);
        cauldron.debtToBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);

        IJoin ilkJoin = IJoin(Mocks.mock("IlkJoin"));
        ladle.joins.mock(vault.ilkId, ilkJoin);
        ilkJoin.exit.mock(bot, minInkOut, minInkOut);
        ilkJoin.exit.verify(bot, minInkOut);

        IJoin baseJoin = IJoin(Mocks.mock("BaseJoin"));
        ladle.joins.mock(series.baseId, baseJoin);
        baseJoin.join.mock(bot, maxBaseIn, maxBaseIn);
        baseJoin.join.verify(bot, maxBaseIn);

        vm.expectEmit(true, true, true, true);
        emit Bought(VAULT_ID, bot, minInkOut, maxBaseIn);

        vm.prank(bot);
        (uint256 inkOut, uint256 baseIn) = witch.payBase(
            VAULT_ID,
            bot,
            minInkOut,
            maxBaseIn
        );
        assertEq(inkOut, minInkOut);
        assertEq(baseIn, maxBaseIn);

        // sum is reduced by the auction.ink
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, auction.ink - minInkOut, "sum");

        _auctionWasUpdated(VAULT_ID, maxBaseIn, minInkOut);
    }

    function testPayBasePartialOnPartiallyLiquidatedVault() public {
        // liquidate 40% of the vault
        testPayBasePartial();
        // Refresh auction copy
        auction = iWitch.auctions(VAULT_ID);

        // Bot Will pay another 20% of the debt (for some reason)
        uint128 maxBaseIn = uint128(auction.art.wmul(0.2e18));
        uint128 minInkOut = uint128(witch.calcPayout(VAULT_ID, maxBaseIn));

        // Reduce balances on tha vault
        cauldron.slurp.mock(VAULT_ID, minInkOut, maxBaseIn, balances);
        cauldron.slurp.verify(VAULT_ID, minInkOut, maxBaseIn);

        // make fyToken 1:1 with base to make things simpler
        cauldron.debtFromBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);
        cauldron.debtToBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);

        IJoin ilkJoin = IJoin(Mocks.mock("IlkJoin"));
        ladle.joins.mock(vault.ilkId, ilkJoin);
        ilkJoin.exit.mock(bot, minInkOut, minInkOut);
        ilkJoin.exit.verify(bot, minInkOut);

        IJoin baseJoin = IJoin(Mocks.mock("BaseJoin"));
        ladle.joins.mock(series.baseId, baseJoin);
        baseJoin.join.mock(bot, maxBaseIn, maxBaseIn);
        baseJoin.join.verify(bot, maxBaseIn);

        vm.expectEmit(true, true, true, true);
        emit Bought(VAULT_ID, bot, minInkOut, maxBaseIn);

        vm.prank(bot);
        (uint256 inkOut, uint256 baseIn) = witch.payBase(
            VAULT_ID,
            bot,
            minInkOut,
            maxBaseIn
        );
        assertEq(inkOut, minInkOut);
        assertEq(baseIn, maxBaseIn);

        // sum is reduced by the auction.ink
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, auction.ink - minInkOut, "sum");

        _auctionWasUpdated(VAULT_ID, maxBaseIn, minInkOut);
    }

    function testPayBaseAll() public {
        uint128 maxBaseIn = uint128(auction.art);
        uint128 minInkOut = uint128(witch.calcPayout(VAULT_ID, maxBaseIn));

        // Reduce balances on tha vault
        cauldron.slurp.mock(VAULT_ID, minInkOut, maxBaseIn, balances);
        cauldron.slurp.verify(VAULT_ID, minInkOut, maxBaseIn);
        // Vault returns to it's owner after all the liquidation is done
        cauldron.give.mock(VAULT_ID, bob, vault);
        cauldron.give.verify(VAULT_ID, bob);

        // make fyToken 1:1 with base to make things simpler
        cauldron.debtFromBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);
        cauldron.debtToBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);

        IJoin ilkJoin = IJoin(Mocks.mock("IlkJoin"));
        ladle.joins.mock(vault.ilkId, ilkJoin);
        ilkJoin.exit.mock(bot, minInkOut, minInkOut);
        ilkJoin.exit.verify(bot, minInkOut);

        IJoin baseJoin = IJoin(Mocks.mock("BaseJoin"));
        ladle.joins.mock(series.baseId, baseJoin);
        baseJoin.join.mock(bot, maxBaseIn, maxBaseIn);
        baseJoin.join.verify(bot, maxBaseIn);

        vm.expectEmit(true, true, true, true);
        emit Bought(VAULT_ID, bot, minInkOut, maxBaseIn);

        vm.prank(bot);
        (uint256 inkOut, uint256 baseIn) = witch.payBase(
            VAULT_ID,
            bot,
            minInkOut,
            maxBaseIn
        );
        assertEq(inkOut, minInkOut);
        assertEq(baseIn, maxBaseIn);

        // sum is reduced by the auction.ink
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, 0, "sum");

        _auctionWasDeleted(VAULT_ID);
    }

    function testPayBaseAllOnPartiallyLiquidatedVault() public {
        // liquidate 40% of the vault
        testPayBasePartial();
        // Refresh auction copy
        auction = iWitch.auctions(VAULT_ID);

        uint128 maxBaseIn = uint128(auction.art);
        uint128 minInkOut = uint128(witch.calcPayout(VAULT_ID, maxBaseIn));

        // Reduce balances on tha vault
        cauldron.slurp.mock(VAULT_ID, minInkOut, maxBaseIn, balances);
        cauldron.slurp.verify(VAULT_ID, minInkOut, maxBaseIn);
        // Vault returns to it's owner after all the liquidation is done
        cauldron.give.mock(VAULT_ID, bob, vault);
        cauldron.give.verify(VAULT_ID, bob);

        // make fyToken 1:1 with base to make things simpler
        cauldron.debtFromBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);
        cauldron.debtToBase.mock(vault.seriesId, maxBaseIn, maxBaseIn);

        IJoin ilkJoin = IJoin(Mocks.mock("IlkJoin"));
        ladle.joins.mock(vault.ilkId, ilkJoin);
        ilkJoin.exit.mock(bot, minInkOut, minInkOut);
        ilkJoin.exit.verify(bot, minInkOut);

        IJoin baseJoin = IJoin(Mocks.mock("BaseJoin"));
        ladle.joins.mock(series.baseId, baseJoin);
        baseJoin.join.mock(bot, maxBaseIn, maxBaseIn);
        baseJoin.join.verify(bot, maxBaseIn);

        vm.expectEmit(true, true, true, true);
        emit Bought(VAULT_ID, bot, minInkOut, maxBaseIn);

        vm.prank(bot);
        (uint256 inkOut, uint256 baseIn) = witch.payBase(
            VAULT_ID,
            bot,
            minInkOut,
            maxBaseIn
        );
        assertEq(inkOut, minInkOut);
        assertEq(baseIn, maxBaseIn);

        // sum is reduced by the auction.ink
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, 0, "sum");

        _auctionWasDeleted(VAULT_ID);
    }

    function testPayFYTokenNotEnoughBought() public {
        // Bot tries to get all collateral but auction just started
        uint128 minInkOut = 50 ether;
        uint128 maxArtIn = 50_000e6;

        vm.expectRevert("Not enough bought");
        witch.payFYToken(VAULT_ID, bot, minInkOut, maxArtIn);
    }

    function testPayFYTokenLeavesDust() public {
        // Bot tries to pay an amount that'd leaves dust
        uint128 maxArtIn = auction.art - 4999e6;
        uint128 minInkOut = uint128(witch.calcPayout(VAULT_ID, maxArtIn));

        vm.expectRevert("Leaves dust");
        witch.payFYToken(VAULT_ID, bot, minInkOut, maxArtIn);
    }

    function testPayFYTokenPartial() public {
        // Bot Will pay 40% of the debt (for some reason)
        uint128 maxArtIn = uint128(auction.art.wmul(0.4e18));
        uint128 minInkOut = uint128(witch.calcPayout(VAULT_ID, maxArtIn));

        // Reduce balances on tha vault
        cauldron.slurp.mock(VAULT_ID, minInkOut, maxArtIn, balances);
        cauldron.slurp.verify(VAULT_ID, minInkOut, maxArtIn);

        IJoin ilkJoin = IJoin(Mocks.mock("IlkJoin"));
        ladle.joins.mock(vault.ilkId, ilkJoin);
        ilkJoin.exit.mock(bot, minInkOut, minInkOut);
        ilkJoin.exit.verify(bot, minInkOut);

        series.fyToken.burn.mock(bot, maxArtIn);
        series.fyToken.burn.verify(bot, maxArtIn);

        vm.expectEmit(true, true, true, true);
        emit Bought(VAULT_ID, bot, minInkOut, maxArtIn);

        vm.prank(bot);
        (uint256 inkOut, uint256 artIn) = witch.payFYToken(
            VAULT_ID,
            bot,
            minInkOut,
            maxArtIn
        );
        assertEq(inkOut, minInkOut);
        assertEq(artIn, maxArtIn);

        // sum is reduced by the auction.ink
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, auction.ink - minInkOut, "sum");

        _auctionWasUpdated(VAULT_ID, maxArtIn, minInkOut);
    }

    function testPayFYTokenPartialOnPartiallyLiquidatedVault() public {
        // liquidate 40% of the vault
        testPayFYTokenPartial();
        // Refresh auction copy
        auction = iWitch.auctions(VAULT_ID);

        // Bot Will pay another 20% of the debt (for some reason)
        uint128 maxArtIn = uint128(auction.art.wmul(0.2e18));
        uint128 minInkOut = uint128(witch.calcPayout(VAULT_ID, maxArtIn));

        // Reduce balances on tha vault
        cauldron.slurp.mock(VAULT_ID, minInkOut, maxArtIn, balances);
        cauldron.slurp.verify(VAULT_ID, minInkOut, maxArtIn);

        IJoin ilkJoin = IJoin(Mocks.mock("IlkJoin"));
        ladle.joins.mock(vault.ilkId, ilkJoin);
        ilkJoin.exit.mock(bot, minInkOut, minInkOut);
        ilkJoin.exit.verify(bot, minInkOut);

        series.fyToken.burn.mock(bot, maxArtIn);
        series.fyToken.burn.verify(bot, maxArtIn);

        vm.expectEmit(true, true, true, true);
        emit Bought(VAULT_ID, bot, minInkOut, maxArtIn);

        vm.prank(bot);
        (uint256 inkOut, uint256 artIn) = witch.payFYToken(
            VAULT_ID,
            bot,
            minInkOut,
            maxArtIn
        );
        assertEq(inkOut, minInkOut);
        assertEq(artIn, maxArtIn);

        // sum is reduced by the auction.ink
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, auction.ink - minInkOut, "sum");

        _auctionWasUpdated(VAULT_ID, maxArtIn, minInkOut);
    }

    function testPayFYTokenAll() public {
        uint128 maxArtIn = uint128(auction.art);
        uint128 minInkOut = uint128(witch.calcPayout(VAULT_ID, maxArtIn));

        // Reduce balances on tha vault
        cauldron.slurp.mock(VAULT_ID, minInkOut, maxArtIn, balances);
        cauldron.slurp.verify(VAULT_ID, minInkOut, maxArtIn);
        // Vault returns to it's owner after all the liquidation is done
        cauldron.give.mock(VAULT_ID, bob, vault);
        cauldron.give.verify(VAULT_ID, bob);

        IJoin ilkJoin = IJoin(Mocks.mock("IlkJoin"));
        ladle.joins.mock(vault.ilkId, ilkJoin);
        ilkJoin.exit.mock(bot, minInkOut, minInkOut);
        ilkJoin.exit.verify(bot, minInkOut);

        series.fyToken.burn.mock(bot, maxArtIn);
        series.fyToken.burn.verify(bot, maxArtIn);

        vm.expectEmit(true, true, true, true);
        emit Bought(VAULT_ID, bot, minInkOut, maxArtIn);

        vm.prank(bot);
        (uint256 inkOut, uint256 baseIn) = witch.payFYToken(
            VAULT_ID,
            bot,
            minInkOut,
            maxArtIn
        );
        assertEq(inkOut, minInkOut);
        assertEq(baseIn, maxArtIn);

        // sum is reduced by the auction.ink
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, 0, "sum");

        _auctionWasDeleted(VAULT_ID);
    }

    function testPayFYTokenAllOnPartiallyLiquidatedVault() public {
        // liquidate 40% of the vault
        testPayFYTokenPartial();
        // Refresh auction copy
        auction = iWitch.auctions(VAULT_ID);
        uint128 maxArtIn = uint128(auction.art);
        uint128 minInkOut = uint128(witch.calcPayout(VAULT_ID, maxArtIn));

        // Reduce balances on tha vault
        cauldron.slurp.mock(VAULT_ID, minInkOut, maxArtIn, balances);
        cauldron.slurp.verify(VAULT_ID, minInkOut, maxArtIn);
        // Vault returns to it's owner after all the liquidation is done
        cauldron.give.mock(VAULT_ID, bob, vault);
        cauldron.give.verify(VAULT_ID, bob);

        IJoin ilkJoin = IJoin(Mocks.mock("IlkJoin"));
        ladle.joins.mock(vault.ilkId, ilkJoin);
        ilkJoin.exit.mock(bot, minInkOut, minInkOut);
        ilkJoin.exit.verify(bot, minInkOut);

        series.fyToken.burn.mock(bot, maxArtIn);
        series.fyToken.burn.verify(bot, maxArtIn);

        vm.expectEmit(true, true, true, true);
        emit Bought(VAULT_ID, bot, minInkOut, maxArtIn);

        vm.prank(bot);
        (uint256 inkOut, uint256 baseIn) = witch.payFYToken(
            VAULT_ID,
            bot,
            minInkOut,
            maxArtIn
        );
        assertEq(inkOut, minInkOut);
        assertEq(baseIn, maxArtIn);

        // sum is reduced by the auction.ink
        (, uint128 sum) = witch.limits(ILK_ID, BASE_ID);
        assertEq(sum, 0, "sum");

        _auctionWasDeleted(VAULT_ID);
    }

    function _auctionWasDeleted(bytes12 vaultId) internal {
        WitchDataTypes.Auction memory auction_ = iWitch.auctions(vaultId);
        assertEq(auction_.owner, address(0));
        assertEq(auction_.start, 0);
        assertEq(auction_.baseId, "");
        assertEq(auction_.art, 0);
        assertEq(auction_.ink, 0);
    }

    function _auctionWasUpdated(
        bytes12 vaultId,
        uint128 art,
        uint128 ink
    ) internal {
        WitchDataTypes.Auction memory auction_ = iWitch.auctions(vaultId);
        assertEq(auction_.owner, auction.owner, "owner");
        assertEq(auction_.start, auction.start, "start");
        assertEq(auction_.baseId, auction.baseId, "baseId");
        assertEq(auction_.art, auction.art - art, "art");
        assertEq(auction_.ink, auction.ink - ink, "ink");
    }
}