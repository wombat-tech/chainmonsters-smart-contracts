import NonFungibleToken from 0xNFTADDRESS
import ChainmonstersNFT from 0xCHAINMONSTERS

// This transaction returns an array of all the nft ids in the collection

pub fun main(account: Address): [UInt64] {
    let acct = getAccount(account)
    let collectionRef = acct.getCapability(/public/RewardCollection)!.borrow<&{ChainmonstersNFT.RewardCollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getIDs()
}
 