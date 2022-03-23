// SPDX-License-Identifier: MIT

pragma solidity^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract FlashWallet is IERC721Receiver, OwnableUpgradeable {
    string public constant name = "Ionization.SmartWallet";
    bytes32 public DOMAIN_SEPARATOR;
    // TypeHash: keccak256(executeCallWithPermit(address receiver,uint256 nativeValue,bytes payload,uint256 nonce,uint256 deadline))
    bytes32 public constant PERMIT_TYPEHASH = 0x438d8c9087d66d7f5a2b945e89688b018b16066886f1546372a8664272bda054;

    uint256 nonce;

    function initialize() public initializer {
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

    function _executeAgent(
        address _receiver, 
        uint256 _nativeValue,
        bytes calldata _payload,
        bool required) internal {
            (bool success, bytes memory returnData) = _receiver.call{value: _nativeValue}(_payload);
            require(required || success, string(returnData));
    }

    function executeMultiCall(
        address[] calldata _receiver, 
        address[] calldata _nativeValue, 
        bytes[] calldata _payload,
        bool[] memory _required) public {

        }

    function executeCallWithPermit(
        address _receiver, 
        uint256 _nativeValue,
        bytes calldata _payload,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        _receiver,
                        _nativeValue,
                        _payload,
                        nonce++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(deadline >= block.timestamp, "Approval Expired");
        require(
            recoveredAddress == owner(),
            "Signature invalid"
        );
        _executeAgent(_receiver, _nativeValue, _payload, false);
    }

    

    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}