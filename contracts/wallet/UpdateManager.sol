// SPDX-License-Identifier: MIT

pragma solidity^0.8.7;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract UpdateManager is ProxyAdmin {
    string public constant name = "Ionization.SmartWallet";
    bytes32 public DOMAIN_SEPARATOR;
    // TypeHash: keccak256("UpgradeSigned(address proxy,address implementation,uint256 nonce, uint256 deadline)")
    bytes32 public constant PERMIT_TYPEHASH = 0x2335763c586ccc9ef214879f2bcd436d179c141adbe32185d3a61ad6af373fd1;

    mapping(address => uint256) public nonces;

    constructor() ProxyAdmin() {
        uint256 id;
        assembly {
            id := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                id,
                address(this)
            )
        );
    }

    modifier OnlyProxyOwner(TransparentUpgradeableProxy proxy) {
        require(getProxyImplementation(proxy) == msg.sender, "Not the owner.");
        _;
    }

    function upgradeSigned(
        address proxy,
        address implementation,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        public {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        proxy,
                        implementation,
                        nonces[proxy]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(deadline >= block.timestamp, "Approval Expired");
        require(
            TransparentUpgradeableProxy(payable(proxy)).admin() == recoveredAddress && 
            recoveredAddress != address(0x0),
            "not the owner of the address"
        );
        TransparentUpgradeableProxy(payable(proxy)).upgradeTo(implementation);
    }

    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public override OnlyProxyOwner(proxy) {
        proxy.changeAdmin(newAdmin);
    }

    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public override OnlyProxyOwner(proxy) {
        proxy.upgradeTo(implementation);
    }

    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable override OnlyProxyOwner(proxy) {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }

}