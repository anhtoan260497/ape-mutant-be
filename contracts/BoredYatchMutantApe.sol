// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

error BoreYatchMutantApe__AlreadyInitialzed();
error BoreYatchMutantApe__ChainNotSupported();
error BoreYatchMutantApe__NotEnoughFeeToMint();
error BoreYatchMutantApe__MaximumTokenExceed();
error BoreYatchMutantApe__IndexExceedTokenUri();
error BoreYatchMutantApe__TokenNotAvailable();
error BoreYatchMutantApe__WidthdrawFailed();

contract BoreYatchMutantApe is
    ERC721URIStorage,
    VRFConsumerBaseV2,
    Ownable,
    ReentrancyGuard
{
    event requestIdToSender(uint256 indexed requestId, address indexed sender);
    event nftMinted(
        uint256 indexed tokenId,
        uint8 indexed nftIndex,
        address indexed sender
    );

    // vrf
    VRFCoordinatorV2Interface i_vrfCoordinator;
    address vrfCoordinator = getVRFCoordinator();
    uint32 internal constant NUM_WORDS = 1;
    uint16 internal constant REQUEST_CONFIRMATIONS = 3;
    uint32 internal immutable i_callbackGasLimit;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subId;

    // vrf helper
    mapping(uint256 => address) public s_requestIdToSender;
    mapping(uint256 => uint256) public s_rareAmount;

    // nft
    uint256 private immutable i_mintFee;
    uint256 private s_tokenCounter; // tokenId Counter
    string[5] private s_tokenUriS;
    bool private s_initialized;
    uint256 internal constant TOTAL_NFTS = 200;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    uint256 public constant denominator = 10000;

    constructor(
        uint256 _mintFee,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint64 _subId,
        string[5] memory _tokenURIs
    )
        ERC721("BoredYatchMutantApe", "BYMA")
        VRFConsumerBaseV2(vrfCoordinator)
        Ownable()
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_callbackGasLimit = _callbackGasLimit;
        i_keyHash = _keyHash;
        i_subId = _subId;

        i_mintFee = _mintFee;
        s_tokenCounter = 0;
        _initialzedContract(_tokenURIs);
    }

    function _initialzedContract(string[5] memory _tokenURIs) private {
        if (s_initialized) revert BoreYatchMutantApe__AlreadyInitialzed();
        s_tokenUriS = _tokenURIs;
        s_initialized = true;
    }

    function getVRFCoordinator() internal view returns (address) {
        if (block.chainid == 1) {
            return 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
        } else if (block.chainid == 11155111) {
            return 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
        } else if (block.chainid == 97) {
            return 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f;
        } else if (block.chainid == 56) {
            return 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
        } else revert BoreYatchMutantApe__ChainNotSupported();
    }

    function getRandomNumber() external payable returns (uint256 _requestId) {
        if(MAX_CHANCE_VALUE < s_tokenCounter) revert BoreYatchMutantApe__MaximumTokenExceed();
        if (msg.value < i_mintFee)
            revert BoreYatchMutantApe__NotEnoughFeeToMint();
        _requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_requestIdToSender[_requestId] = msg.sender;
        emit requestIdToSender(_requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        address sender = s_requestIdToSender[_requestId];
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter++;
        uint256 number = _randomWords[0] % MAX_CHANCE_VALUE;
        console.log(number);
        uint8 index = getTokenUriIndex(number);
        s_rareAmount[index]++;
        _safeMint(sender, newItemId);
        _setTokenURI(newItemId, s_tokenUriS[index]);
        emit nftMinted(newItemId, index, sender);
    }

    function getTokenUriIndex(uint256 _number) internal view returns (uint8) {
        uint256 cumulativesum = 0;
        uint8[5] memory chanceArray = getChanceArray();
        for (uint8 i = 0; i < chanceArray.length; i++) {
            if (
                _number >= cumulativesum &&
                _number < cumulativesum + chanceArray[i]
            ) {
                return calculateToken(chanceArray[i]);
            }
        }
        revert BoreYatchMutantApe__TokenNotAvailable();
    }

    function getChanceArray() internal pure returns (uint8[5] memory) {
        return [1, 6, 13, 30, 50];
    }

    function calculateToken(uint8 _index) internal view returns (uint8) {
        uint8[5] memory chanceArray = getChanceArray();
        if (_index > chanceArray.length - 1)
            revert BoreYatchMutantApe__IndexExceedTokenUri();
        uint256 currentAmount = s_rareAmount[_index];
        uint256 maxAmount = (TOTAL_NFTS * (chanceArray[_index] * 100)) /
            denominator; // basis point
        if (currentAmount < maxAmount) {
            return _index;
        } else {
            calculateToken(_index++);
        }

        revert BoreYatchMutantApe__TokenNotAvailable();
    }

    function widthdraw() external onlyOwner nonReentrant {
        uint256 amount  =  address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success)revert BoreYatchMutantApe__WidthdrawFailed();
    }

    function getMintFee() external view returns(uint256) {
        return i_mintFee;
    }

    function getTokenUri(uint8 _index) external view returns (string memory) {
        return s_tokenUriS[_index];
    }

    function getTokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }

    function getAmountOfRare(uint8 _index) external view returns (uint256) {
        return s_rareAmount[_index];
    }
}
