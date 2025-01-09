// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleIntegrationTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    VRFCoordinatorV2_5Mock vrfCoordinator;
    LinkToken linkToken;

    function setUp() external {
        // Deploy mocks
        vrfCoordinator = new VRFCoordinatorV2_5Mock(0.25 ether, 1e9, 4e15);
        linkToken = new LinkToken();

        // Deploy helper configuration
        helperConfig = new HelperConfig();

        // Deploy raffle contract
        HelperConfig.NetworkConfig memory config = helperConfig.getOrCreateAnvilEthConfig();
        raffle = new Raffle(
            config.entranceFee,
            config.interval,
            address(vrfCoordinator),
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
    }

    function testDeployContract() public {
        // Arrange
        DeployRaffle deployRaffle = new DeployRaffle();

        // Act
        (raffle, helperConfig) = deployRaffle.deployContract();

        // Assert
        assert(raffle.getSubscriptionId() != 0);
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        assert(config.vrfCoordinator != address(0));
        assert(
            VRFCoordinatorV2_5Mock(config.vrfCoordinator).consumerIsAdded(
                raffle.getSubscriptionId(),
                address(raffle)
            )
        );
    }

    function testCreateSubscription() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();

        // Act
        (uint256 subscriptionId, ) = createSubscription.createSubscription(
            helperConfig.getConfig().vrfCoordinator,
            helperConfig.getConfig().account
        );

        // Assert
        assert(subscriptionId != 0);
    }

    function testFundSubscription() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        (uint256 subscriptionId, ) = createSubscription.createSubscription(
            helperConfig.getConfig().vrfCoordinator,
            helperConfig.getConfig().account
        );

        // Act
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(
            helperConfig.getConfig().vrfCoordinator,
            subscriptionId,
            helperConfig.getConfig().link,
            helperConfig.getConfig().account
        );

        // Assert
       (uint256 balance, , , ,) = VRFCoordinatorV2_5Mock(helperConfig.getConfig().vrfCoordinator).getSubscription(subscriptionId);
        assert(balance > 0);
      
    }

    function testAddConsumer() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        (uint256 subscriptionId, ) = createSubscription.createSubscription(
            helperConfig.getConfig().vrfCoordinator,
            helperConfig.getConfig().account
        );
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(
            helperConfig.getConfig().vrfCoordinator,
            subscriptionId,
            helperConfig.getConfig().link,
            helperConfig.getConfig().account
        );

        // Act
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            helperConfig.getConfig().vrfCoordinator,
            subscriptionId,
            helperConfig.getConfig().account
        );

        // Assert
        assert(
            VRFCoordinatorV2_5Mock(helperConfig.getConfig().vrfCoordinator).consumerIsAdded(
                subscriptionId,
                address(raffle)
            )
        );
    }

    function testRaffleWorkflow() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        (uint256 subscriptionId, ) = createSubscription.createSubscription(
            helperConfig.getConfig().vrfCoordinator,
            helperConfig.getConfig().account
        );
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(
            helperConfig.getConfig().vrfCoordinator,
            subscriptionId,
            helperConfig.getConfig().link,
            helperConfig.getConfig().account
        );
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            helperConfig.getConfig().vrfCoordinator,
            subscriptionId,
            helperConfig.getConfig().account
        );

        // Act: Enter the raffle
        vm.deal(address(1), 1 ether);
        vm.startPrank(address(1));
        raffle.enterRaffle{value: helperConfig.getConfig().entranceFee}();
        vm.stopPrank();

        // Assert: Validate player entry
        assertEq(raffle.getRafflePlayers(0), address(1), "Player address should match.");
    }
}
