// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 < 0.9.0;

struct Request {
    uint space;
    uint duplications;
    uint duration;
    string[] cids;
    uint startTime;
}

struct Provide {
    uint space;
}

// duration 
// access data 

contract System {

    modifier afterCompletion(address r) {
        uint deadline = requesterList[r].startTime + requesterList[r].duration;
        require(block.timestamp > deadline);
        _;
    }


    address[] public requesters;
    address[] public providers;
    mapping (address => Request) public requesterList;
    mapping (address => Provide) public providerList;

    // one provider can have multiple requesters
    mapping (address => address[]) public providerToRequester;

    // one requester can have multiple providers
    mapping (address => address[]) public requesterToProvider;

    //address to amount paid  by requester and deposited to the contract account and not released to the provider account yet
    mapping (address => uint) public requesterFunds;
    
    modifier onlyRequester {
        bool flag = false;
        for(uint i=0; i<requesters.length; i++) {
            if(msg.sender == requesters[i]) flag = true;
        }
        require(flag == true);
        _;
    }

    modifier onlyProvider {
        bool flag = false;
        for(uint i=0; i<providers.length; i++) {
            if(msg.sender == providers[i]) flag = true;
        }
        require(flag == true);
        _;
    }


    function addRequester() public{
        address requester = msg.sender;
        bool flag = true;
        for(uint i=0; i<requesters.length; i++) {
            if(requesters[i] == requester) flag = false;
        }
        for(uint i=0; i<providers.length; i++) {
            if(providers[i] == requester) flag = false;
        }
        if(flag) requesters.push(msg.sender);
    }

    function addProvider(uint _spaceInMB) public {
        address pro = msg.sender;
        bool flag = true;
        for(uint i=0; i<requesters.length; i++) {
            if(requesters[i] == pro) flag = false;
        }
        for(uint i=0; i<providers.length; i++) {
            if(providers[i] == pro) flag = false;
        }
        if(flag) {
            providers.push(msg.sender);

            Provide memory p = Provide(_spaceInMB);
            providerList[msg.sender] = p;
        }
    }

    
    // front end should give array of cids as argument to this func
    function requestSpace(uint _spaceInMB, uint _duplications, uint _duration, string[] memory _cids) public payable onlyRequester {
        // duration in seconds
        // price is a function of requesters space, duration and duplications
        // uint price = 2000000000000000000;
        // msg.value = price;
        require(msg.sender.balance > msg.value);
        
        Request memory r = Request(_spaceInMB, _duplications, _duration, _cids, 0);
        requesterList[msg.sender] = r;
        payRent();

        // keeping track of amount deposited to contract account by each requester
        requesterFunds[msg.sender] = msg.value;

        // withdraw money from requesters account
        // put it into contarcts account
        // release into provider after durtion is complete

        // transfer is from contract to any other payable address
        // payable(address(this)).transfer(msg.value);       
    }

    function payRent() payable public {
        //learn how to hide this function
    }

    function approveRequest (address requester) public onlyProvider {
        address caller = msg.sender;
        
        if(providerList[caller].space != 0) {
            if(requesterList[requester].space < providerList[caller].space) {
                if(requesterToProvider[requester].length < requesterList[requester].duplications) {
                    providerToRequester[caller].push(requester);
                    requesterToProvider[requester].push(caller);

                    providerList[caller].space -= requesterList[requester].space;

                    // saving the start time
                    requesterList[requester].startTime = block.timestamp;
                }

                else {
                    // already y providers exist
                }
            }
            else {
                // space insufficient
            }
        }
        else {
            // not a provider
        }
    }

    // releasePayment() is called by provider. it checks the duration and transfers the funds
    // argument is requesters address
    function releasePayment (address r) public afterCompletion(r) {
        require(providerToRequester[msg.sender].length != 0);
        uint amount = requesterFunds[r]/requesterList[r].duplications;
        payable(msg.sender).transfer(amount);
    }
}
