pragma solidity ^0.6.0;

contract Timer {
    uint _start;
    uint _end;

    modifier timeOver{
        require(now<=_end, "The timer is Over");
        _;
    }

    function start() public {
        _start = now;
    }

    function end(uint totaltime) public {
        _end = _start + totaltime;
    }

    function getTime() public timeOver view returns (uint) {
        return _end-now;
    }
}
