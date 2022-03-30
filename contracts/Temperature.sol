// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";

// @title Simple Oracle Contract for Decenteralized Temperature
// @author  Yuki Wadana
contract Temperature is Ownable {
  
  uint256 roundId = 0;                    //increasing request id
  uint256 minQuorum = 1;                  //minimum number of responses to receive before declaring final result
  uint256 totalOracleCount = 0;           // Hardcoded oracle count
  
  mapping(uint256 => Request) requests;

  // defines a general api request
  struct Request {
    uint256 id;                           //request id    
    uint256 temperature;                  //value from key
    mapping(uint256 => uint256) anwers;   //answers provided by the oracles
    mapping(address => uint256) quorum;   //oracles which will query the answer (1=oracle hasn't voted, 2=oracle has voted)
  }
  
 mapping(address => uint256) oracles;

  //event that triggers oracle outside of the blockchain
  event NewRequest (uint256 id);

  //triggered when there's a consensus on the final result
  event UpdatedRequest (
    uint256 id,
    uint256 agreedValue
  );

  constructor (address[] memory _oracles)  {
      for(uint256 i =0; i<_oracles.length ; i++){
          oracles[_oracles[i]] = 1;
      }
      totalOracleCount = _oracles.length;
  }

  function createRequest () external
  {
    Request storage r = requests[roundId];

    r.id = roundId;  

    // launch an event to be detected by oracle outside of blockchain
    emit NewRequest (roundId); 

    roundId = roundId + 1;   
  }

  // setter of temperature
  // called by the oracle to record its answer
  function updateRequest (
    uint256 _roundId,
    uint256 _tempValue
  ) external {

    Request storage currRequest = requests[_roundId];

    //check if oracle is in the list of trusted oracles
    //and if the oracle hasn't voted yet
    if(oracles[msg.sender] == 1 && currRequest.quorum[address(msg.sender)] == 0){

      //marking that this address has voted
      currRequest.quorum[msg.sender] = 1;

      //iterate through "array" of answers until a position if free and save the retrieved value
      uint256 tmpI = 0;
      bool found = false;
      while(!found) {
        //find first empty slot
        if(currRequest.anwers[tmpI] == 0){
          found = true;
          currRequest.anwers[tmpI] = _tempValue;
        }
        tmpI++;
      }

      uint256 currentQuorum = 0;

      //iterate through oracle list and check if enough oracles(minimum quorum)
      //have voted the same answer has the current one
      for(uint256 i = 0; i < totalOracleCount; i++){
 
        if(currRequest.anwers[i] == _tempValue){
          currentQuorum++;
          if(currentQuorum >= minQuorum){
            currRequest.temperature = _tempValue;
            emit UpdatedRequest (
              currRequest.id,              
              currRequest.temperature
            );
          }
        }
      }      
    }
  }

  // getter of temperature
  function getLastRoundData() external view returns (uint256){
    require(roundId > 0, 'No round data');
    return requests[roundId - 1].temperature;
  }
}