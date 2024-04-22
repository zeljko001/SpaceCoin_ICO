// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {SpaceCoin} from "../src/SpaceCoin.sol";
import {Ico} from "../src/Ico.sol";

contract DeploySPC is Script {
    function run() external returns (SpaceCoin, Ico) {
        Ico ico;
        address treasury = 0x9161D2fB4705DADEa76681626aa070E19E153Ba2;
        vm.startBroadcast();
        SpaceCoin spc = new SpaceCoin(treasury);
        ico = spc.getIco();
        vm.stopBroadcast();
        return (spc, ico);
    }
}
