// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC1155} from "@openzeppelin/contracts@5.3.0/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts@5.3.0/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts@5.3.0/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts@5.3.0/access/Ownable.sol";

contract Mfer1155 is ERC1155, ERC1155Burnable, Ownable, ERC1155Supply {
    constructor()
        ERC1155("ipfs://QmWiQE65tmpYzcokCheQmng2DCM33DEhjXcPB6PanwpAZo/")
        Ownable(msg.sender)
    {}

    error InvalidTime();
    error OutsideMintingTimeframe();
    error MintingPhaseStopped();
    error InsufficientFunds();
    error MintingPhaseSuppleReached();
    error PhaseAlreadyStopped();
    error UserAlreadyHaveToken();
    error MaxAvailablePurchaseReached();

    event MintPhaseCreated(
        uint256 phaseId,
        uint256 startTime,
        uint256 endTime,
        uint256 tokenId,
        uint256 price,
        uint256 maxSupply
    );

    struct MintPhase {
        uint256 startTime;
        uint256 endTime;
        uint256 tokenId;
        uint256 price;
        uint256 mintedDuringPhase;
        uint256 maxSupply;
        bool stopped;
    }

    struct UserPhase {
        uint256 phaseId;
        uint256 tokenId;
        uint256 amount;
    }

    uint256 public lastPhase; // сколько фаз создано
    /// @notice phase_id => struct_of_phase
    mapping(uint256 => MintPhase) public mintPhases;
    /// @notice buyer => phases
    mapping(address => UserPhase[]) public userPhases;

    function mint(
        uint256 _phaseId,
        uint256 _amount
    ) external payable {
        MintPhase storage phase = mintPhases[_phaseId];
        UserPhase[] storage userPhase = userPhases[msg.sender];

        bool alreadyExist = false;
        for(uint256 i = 0; i < userPhase.length; i++) {
            if(userPhase[i].phaseId == _phaseId) {
                alreadyExist = true;
            }
        }

        require(!alreadyExist, UserAlreadyHaveToken());
        require(block.timestamp >= phase.startTime && block.timestamp <= phase.endTime, OutsideMintingTimeframe());
        require(!phase.stopped, MintingPhaseStopped());
        require(msg.value >= phase.price * _amount, InsufficientFunds());
        require(phase.mintedDuringPhase + _amount <= phase.maxSupply, MintingPhaseSuppleReached());

        phase.mintedDuringPhase += _amount;
        userPhases[msg.sender].push(UserPhase({
            phaseId: _phaseId,
            tokenId: phase.tokenId,
            amount: _amount
        }));

        _mint(msg.sender, phase.tokenId, _amount, "");

        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function mintForOwner(
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyOwner {
        _mintBatch(msg.sender, ids, amounts, "");
    }

    function createMintPhase(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _tokenId,
        uint256 _price,
        uint256 _maxSupply
    ) external onlyOwner {
        require(_endTime > _startTime, InvalidTime());

        uint256 phaseId = lastPhase;

        mintPhases[lastPhase + 1] = MintPhase({
            startTime: _startTime,
            endTime: _endTime,
            tokenId: _tokenId,
            price: _price,
            mintedDuringPhase: 0,
            maxSupply: _maxSupply,
            stopped: false
        });

        lastPhase++;

        emit MintPhaseCreated(phaseId, _startTime, _endTime, _tokenId, _price, _maxSupply);
    }

    function getMintPhaseInfo(uint256 _phaseId) external view returns(MintPhase memory) {
        return mintPhases[_phaseId];
    }

    function isMintPhaseActive(uint256 _phaseId) external view returns(bool) {
        return mintPhases[_phaseId].stopped;
    }

    // homework
    function stopMintPhase(uint256 _phaseId) external onlyOwner {
        MintPhase storage phase = mintPhases[_phaseId];
        require(!phase.stopped, PhaseAlreadyStopped());

        phase.stopped = true;
    }


    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}
