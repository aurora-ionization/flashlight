// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FlashloanWhitelist is Ownable {
    event WhitelistUpdate(address loaner, bool state);
    mapping(address => bool) whitelist;
    function addWhiteList(address provider) public onlyOwner {
        whitelist[provider] = true;
        emit WhitelistUpdate(provider, true);
    }
    function removeWhiteList(address provider) public onlyOwner {
        whitelist[provider] = false;
        emit WhitelistUpdate(provider, false);
    }
}