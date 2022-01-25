// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

contract OnChainNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string[] public wordValues = ["meow", "cow", "lao", "chow", "pow", "DAO"];

  struct Word {
      string name;
      string description;
      string bgHue;
      string txtHue;
      string value;
  }

  mapping (uint => Word) public words;

  constructor() ERC721("On Chain NFT", "OCNFT") {}

  // public
  function mint() public payable {
    uint256 supply = totalSupply();
    require(supply + 1 <= 10000); // 10K max supply

    Word memory newWord = Word(
      string(abi.encodePacked('OCNFT #',uint(supply + 1).toString())),
      "This is my first on-chain NFT :)",
      randomNum(361, block.difficulty, supply).toString(),
      randomNum(361, block.timestamp, supply).toString(),
      wordValues[randomNum(wordValues.length, block.timestamp, supply)]
    );

    if (msg.sender != owner()) {
      require(msg.value >= 0.005 ether);
    }

    words[supply + 1] = newWord;

    _safeMint(msg.sender, supply + 1);
  }

  function randomNum(uint _mod, uint _seed, uint _salt) public view returns(uint) {
      uint num = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
      return num;
  }

  function buildImage(uint _tokenId) public view returns(string memory) {
      Word memory currentWord = words[_tokenId];

      return Base64.encode(bytes(abi.encodePacked(
          '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">',
          '<rect height="500" width="500" y="0" x="0" fill="hsl(',currentWord.bgHue,',50%,25%)"/>',
          '<text dominant-baseline="middle" text-anchor="middle" font-size="24" y="50%" x="50%" fill="hsl(',currentWord.txtHue,',100%,80%)">',currentWord.value,'</text>',
          '</svg>'
      )));
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    Word memory currentWord = words[_tokenId];

    return string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(bytes(abi.encodePacked(
            '{"name":"',
                currentWord.name,
                '", "description":"',
                currentWord.description,
                '", "image": "',
                'data:image/svg+xml;base64,',
                buildImage(_tokenId),
                '"}'
        )))
    ));
  }
 

 // only owner
  function withdraw() public payable onlyOwner {
    // This will pay HashLips 5% of the initial sale.
    // You can remove this if you want, or keep it in to support HashLips and his channel.
    // =============================================================================
    (bool hs, ) = payable(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D).call{value: address(this).balance * 5 / 100}("");
    require(hs);
    // =============================================================================
    
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}