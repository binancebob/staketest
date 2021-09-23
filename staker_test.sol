pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Funny money has an infinite supply tho only 10,000 max can be created per day if all Washington mints are staked. (unlikely)
//   Contract starts and sets start date to a unix time 
//   When someone clicks stake it adds them to the staking and updates their token balance with +1 every 24 hours 

// FUNCTIONS NEEDED FROM NFT CONTRACT: 
// contract calls approve token iD ?? Think this is needed
// contract safetransfers to the locker 

// contract safetransfers to the unlocker if they locked that NFT

interface PresidentsInterface {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

    
contract FunnyMoneyStaker is ERC20, Ownable, IERC721Receiver {
    
    address PresidentsInterfaceAddress = 0xE6D2ad0AE40E2F40f1a47EF1aFC9DbE174a00034; 
    // ^ The address of the Washie contract on Ethereum
    PresidentsInterface presidentContract = PresidentsInterface(PresidentsInterfaceAddress);
    // Now `presidentsContract` is pointing to the washie contract

   
    uint256 public day = 86400;
    uint256 public start;
    
    uint256 public currentSupply;
    uint256 public totalStaked;
    
    address[] public stakeholders;
    
    mapping (address => bool) public isStaked;
    mapping (address => mapping (uint256 => uint256)) public timeStaked;
    mapping (address => mapping (uint256 => uint256)) public timeUnstaked;
    mapping (address => uint256) public amountLocked;
    
    mapping (address => uint256) public internalBalance;
    
    mapping (address => mapping (uint256 => bool)) private lockedPresidents;
    
    constructor() public ERC20("FunnyMoney", "BUCK") {
        start = block.timestamp;
    }
    
    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    function test() public view returns (uint) {
        return presidentContract.totalSupply();
    }
    
    function totalSupply() public view override returns (uint256) {
        return currentSupply;
    }
    

    // token owner must approve first directly from token contract then can use stake().     
    function stake(uint256 _tokenID) public {
        
        require(lockedPresidents[msg.sender][_tokenID] = false, "You have already locked this President");
        totalStaked += 1;
        timeStaked[msg.sender][_tokenID] = block.timestamp;
        lockedPresidents[msg.sender][_tokenID] = true; 
        amountLocked[msg.sender] += 1;
        presidentContract.safeTransferFrom(msg.sender, address(this), _tokenID);
    }
    
    function unstake(uint256 _tokenID) public {
        require(lockedPresidents[msg.sender][_tokenID] = true, "This President is not locked");
        totalStaked -= 1;
        timeUnstaked[msg.sender][_tokenID] = block.timestamp;
        lockedPresidents[msg.sender][_tokenID] = false; 
        amountLocked[msg.sender] -= 1;
        presidentContract.safeTransferFrom(address(this), msg.sender, _tokenID);
    }
    
    
    
    function outstandingrewardsOf(address account) public view returns(uint256) {
        // require(timeStaked[account] > 0, "You have no Washingtons staked or have just staked this block");
        uint256 a =  amountLocked[msg.sender];
        uint256 total = 0;
        for (uint i = 0; i < a; i++) {
            uint256 secondsBetween = ( block.timestamp - timeStaked[account][i]);
            total += secondsBetween;
        }
        return total;
    }
    
    
    function withdrawRewards() public {
        uint256 rewards = outstandingrewardsOf(msg.sender);
        
        uint256 b =  amountLocked[msg.sender];
        for (uint i = 0; i < b; i++) {
            timeStaked[msg.sender][i] = block.timestamp;
        }
        _mint(msg.sender, rewards); 
        currentSupply += rewards;
    }
}
