// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {MyGovernor} from "../src/MyGovernor.sol";
import {GovToken} from "../src/GovToken.sol";
import {Box} from "../src/Box.sol";
import {TimeLock} from "../src/TimeLock.sol";

import {Test,console} from "../lib/forge-std/src/Test.sol";


contract MyGovernorTest is Test {
    
    MyGovernor governor;
    Box box;
    GovToken govToken;
    TimeLock timelock;

    address public user = makeAddr("USER");
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    address[] proposers;
    address[] executors;
    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes 
    uint256 public constant VOTING_DELAY = 1; // how many blocks till a vote is active
    uint256 public constant VOTING_PERIOD = 50400;


    function setUp() public {
        govToken = new GovToken();
        govToken.mint(user,INITIAL_SUPPLY);
        // Minting token does not means we have voting power, we need to delegate these tokens to ourselves so we can vote
        vm.startPrank(user);
        govToken.delegate(user);
        timelock = new TimeLock(MIN_DELAY,proposers,executors);
        governor = new MyGovernor(govToken,timelock);
        //Now, we need to grant some roles. The TimeLock starts with some default roles and we need to grant governor with some 
        // roles and then we need to remove ourselves as admin of the timelock as we dont want single centralized entity to have 
        // power over it

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.TIMELOCK_ADMIN_ROLE();

        // Only the governor can propose to timelock
        timelock.grantRole(proposerRole, address(governor));
        // This means anybody can execute a passed proposal
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, user);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timelock));

    }


    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }


    function testUpdatesGovernanceBox() public {
        uint256 valueToStore = 999999;

        string memory description = "Store in Box";
        //Getting calldata for the proposal
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        values.push(0);
        calldatas.push(encodedFunctionCall);
        targets.push(address(box));

        // 1. Propose to the Dao
        uint256 proposalId = governor.propose(targets,values,calldatas,description);

        // 2. View the state of the Proposal
        console.log("Proposal State: ", uint256(governor.state(proposalId)));

        vm.warp(block.timestamp+VOTING_DELAY+1);
        vm.warp(block.number+VOTING_DELAY+1);

        // 3. Vote on the Proposal 

        string memory reason = "This is the first Proposal";

        uint8 voteway = 1;
        vm.prank(user);
        governor.castVoteWithReason(proposalId, voteway, reason);

        vm.warp(block.timestamp+VOTING_PERIOD+1);
        vm.warp(block.number+VOTING_PERIOD+1);






    }
}