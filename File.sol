// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IERC20
{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract ICO
{
    event ExtractedToken(address indexed from, address indexed to, uint256 value);
    event ExtractedEther(address indexed from, address indexed to, uint256 value);
    event ClaimedTokens(address indexed to, uint256 value);

    address private _owner;
    bool private _isICOActive;
    uint256 private _start;

    IERC20 private _token;
    uint8 private _decimals;
    uint256 private _tokenRate;
    uint256 private _fundingGoal;
    uint256 private _etherRaised;

    mapping(address => uint256) _invested;
    mapping(address => uint256) _claimed;
    mapping(address => uint256) _everydayClaim;
    mapping(address => uint256) _lastClaimed;

    bool private _isClaimable;
    bool private _nextClaim;

    constructor()
    {
        _owner = msg.sender;
        _isICOActive = false;
        _isClaimable = false;
    }

    modifier onlyOwner
    {
        require(msg.sender == _owner, "Permission Denied!");
        _;
    }

    function setICO(address tokenAddress, uint8 decimals, uint256 tokenRate, uint256 fundingGoal) onlyOwner external
    {
        _token = IERC20(tokenAddress);

        _decimals = decimals;
        _tokenRate = tokenRate;
        _fundingGoal = fundingGoal;
    }

    function enableICO() onlyOwner external
    {
        _isICOActive = true;
    }

    function disbaleICO() onlyOwner external
    {
        _isICOActive = false;
    }

    function isICOActive() external view returns (bool)
    {
        return _isICOActive;
    }

    function extractTokens(uint256 amount) onlyOwner external returns (bool)
    {
        _token.transfer(_owner, amount * (10 **  _decimals));
        emit ExtractedToken(address(this), _owner, amount);
        return true;
    }

    function extractAllTokens() onlyOwner external returns (bool)
    {
        _token.transfer(_owner, _token.balanceOf(address(this)));
        emit ExtractedToken(address(this), _owner, _token.balanceOf(address(this)));
        return true;
    }

    function extractEther(uint256 amount) onlyOwner external returns (bool)
    {
        require(address(this).balance >= 0, "Zero Balance!");
        payable(msg.sender).transfer(amount * 1 ether);
        emit ExtractedEther(address(this), _owner, amount);
        return true;
    }

    function extractAllEther() onlyOwner external returns (bool)
    {
        require(address(this).balance >= 0, "Zero Balance!");
        payable(msg.sender).transfer(address(this).balance);
        emit ExtractedEther(address(this), _owner, address(this).balance);
        return true;
    }

    receive() external payable
    {
        buy();
    }

    function buy() public payable returns (bool)
    {
        require(_isICOActive, "ICO is not active!");
        require((_etherRaised != _fundingGoal * 1 ether), "Reached Fundraising Goal!");
        require(msg.value <= (_fundingGoal * 1 ether - _etherRaised), "Try smaller amount!");

        if(_fundingGoal == _etherRaised)
        {
            _isICOActive = false;
        }
        else
        {
            _etherRaised += msg.value;
            _invested[msg.sender] += msg.value * _tokenRate;
            _everydayClaim[msg.sender] = msg.value * _tokenRate / 100;
        }

        return true;
    }

    function enableClaim() onlyOwner external
    {
       require(_isClaimable == false, "Claim is already active!");
       _isClaimable = true;
       _start = block.timestamp;
    }

    function isClaimable() external view returns (bool)
    {
        return _isClaimable;
    }
    function claimToken() external returns (bool)
    {
        require(_isClaimable, "Claim Disabled!");
        require(_invested[msg.sender] != 0, "Zero Investment!");
        require(_lastClaimed[msg.sender] <= 100, "Claimed all, no more claims!");
        require(checkDay() - _lastClaimed[msg.sender] >= 5 seconds, "Already claimed, wait for next Claim!"); ///

        if((checkDay() ) > 100 && _lastClaimed[msg.sender] == 0)
        {
            _token.transfer(msg.sender, _invested[msg.sender]);
            emit ClaimedTokens(msg.sender, _invested[msg.sender]);

            _claimed[msg.sender] = _invested[msg.sender];
            _invested[msg.sender] -= 0;
        }

        if((checkDay() - _lastClaimed[msg.sender]) > 100)
        {
            _token.transfer(msg.sender, (100 - _lastClaimed[msg.sender]) * _everydayClaim[msg.sender]);
            emit ClaimedTokens(msg.sender, (100 - _lastClaimed[msg.sender]) * _everydayClaim[msg.sender]);

            _claimed[msg.sender] += (100 - _lastClaimed[msg.sender]) * _everydayClaim[msg.sender];
            _invested[msg.sender] -= (100 - _lastClaimed[msg.sender]) * _everydayClaim[msg.sender];
        }
        else
        {
            _token.transfer(msg.sender, (checkDay() - _lastClaimed[msg.sender]) * _everydayClaim[msg.sender]);
            emit ClaimedTokens(msg.sender, (checkDay() - _lastClaimed[msg.sender]) * _everydayClaim[msg.sender]);

            _invested[msg.sender] -= (checkDay() - _lastClaimed[msg.sender]) * _everydayClaim[msg.sender];
            _claimed[msg.sender] += (checkDay() - _lastClaimed[msg.sender]) * _everydayClaim[msg.sender];
        }
        
        _lastClaimed[msg.sender] = checkDay();

        return true;
    }

    function checkDay() view public returns (uint8)
    {
        if(_start == 0) return 0;
        else return uint8((block.timestamp - _start) / 5 seconds); ///
    }
}
    
