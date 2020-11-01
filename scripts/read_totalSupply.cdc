import ChainmonstersNFT from 0xCHAINMONSTERS

// This script reads the current number of NFTs that have been minted
// from the Chainmonsters contract and returns that number to the caller

pub fun main(): UInt64 {
    return ChainmonstersNFT.totalSupply
}
