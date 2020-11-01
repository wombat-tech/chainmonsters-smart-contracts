// This is the Kickstarter/Presale NFT contract of Chainmonsters.
// Based on the "current" NonFungibleToken standard on Flow.
// Does not include that much functionality as the only purpose it to mint and store the Presale NFTs.

import NonFungibleToken from 0xNFTADDRESS

pub contract ChainmonstersNFT: NonFungibleToken {

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub event RewardCreated(id: UInt32, metadata: {String:String})
    pub event NFTMinted(NFTID: UInt64, rewardID: UInt32, serialNumber: UInt32)

    pub var nextRewardID: UInt32

    // Variable size dictionary of Reward structs
    // TBD: Do we re-use this contract here for the Pre-Season Pass??
    // Or do we stay with the KS only NFTs
    access(self) var rewardDatas: {UInt32: Reward}
    access(self) var rewardSupplies: {UInt32: UInt32}

    // a mapping of Reward IDs that indicates what serial/mint number
    // have been minted for this specific Reward yet
    pub var numberMintedPerReward: {UInt32: UInt32}



    // A reward is a struct that keeps all the metadata information from an NFT in place.
    // There are 19 different rewards and all need an NFT-Interface.
    // Depending on the Reward-Type there are different ways to use and interact with future contracts.
    // E.g. the "Alpha Access" NFT needs to be claimed in order to gain game access with your account.
    // This process is destroying/moving the NFT to another contract.
    pub struct Reward {

        // The unique ID for the Reward
        pub let rewardID: UInt32

        // Stores all the metadata about the reward as a string mapping
        // Blatantly "inspired" by TopShots due to lack of better solution for now.
        //
        pub let metadata: {String: String}

        init(metadata: {String: String}) {
            pre {
                metadata.length != 0: "New Reward metadata cannot be empty"
            }
            self.rewardID = ChainmonstersNFT.nextRewardID
            self.metadata = metadata

            // Increment the ID so that it isn't used again
            ChainmonstersNFT.nextRewardID = ChainmonstersNFT.nextRewardID + UInt32(1)

            emit RewardCreated(id: self.rewardID, metadata: metadata)
        }
    }

     pub struct NFTData {

        // The ID of the Reward that the NFT references
        pub let rewardID: UInt32

        // The token mint number
        // Otherwise known as the serial number
        pub let serialNumber: UInt32

        init(rewardID: UInt32, serialNumber: UInt32) {
            self.rewardID = rewardID
            self.serialNumber = serialNumber
        }

    }


    pub resource NFT: NonFungibleToken.INFT {
        
        // Global unique NFT ID
        pub let id: UInt64

        pub let data: NFTData

        init(serialNumber: UInt32, rewardID: UInt32) {
            // Increment the global NFT IDs
            ChainmonstersNFT.totalSupply = ChainmonstersNFT.totalSupply + UInt64(1)
            
            self.id = ChainmonstersNFT.totalSupply 

            self.data = NFTData(rewardID: rewardID, serialNumber: serialNumber)

            emit NFTMinted(NFTID: self.id, rewardID: rewardID, serialNumber: self.data.serialNumber)
        }
    }

    // This is the interface that users can cast their Reward Collection as
    // to allow others to deposit Rewards into their Collection. It also allows for reading
    // the IDs of Rewards in the Collection.
    pub resource interface RewardCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowReward(id: UInt64): &ChainmonstersNFT.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id): 
                    "Cannot borrow Reward reference: The ID of the returned reference is incorrect"
            }
        }
    }


    pub resource Collection: RewardCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT-Reward from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {

            // Remove the nft from the Collection
            let token <- self.ownedNFTs.remove(key: withdrawID) 
                ?? panic("Cannot withdraw: Reward does not exist in the collection")

            emit Withdraw(id: token.id, from: self.owner?.address)
            
            // Return the withdrawn token
            return <-token
        }


        // batchWithdraw withdraws multiple tokens and returns them as a Collection
        //
        // Parameters: ids: An array of IDs to withdraw
        //
        // Returns: @NonFungibleToken.Collection: A collection that contains
        //                                        the withdrawn rewards
        //
        pub fun batchWithdraw(ids: [UInt64]): @NonFungibleToken.Collection {
            // Create a new empty Collection
            var batchCollection <- create Collection()
            
            // Iterate through the ids and withdraw them from the Collection
            for id in ids {
                batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
            }
            
            // Return the withdrawn tokens
            return <-batchCollection
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @ChainmonstersNFT.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // batchDeposit takes a Collection object as an argument
        // and deposits each contained NFT into this Collection
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {

            // Get an array of the IDs to be deposited
            let keys = tokens.getIDs()

            // Iterate through the keys in the collection and deposit each one
            for key in keys {
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }

            // Destroy the empty Collection
            destroy tokens
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowMReward returns a borrowed reference to a Reward
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        pub fun borrowReward(id: UInt64): &ChainmonstersNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &ChainmonstersNFT.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }




    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
	pub resource Admin {

        
        // creates a new Reward struct and stores it in the Rewards dictionary
        // Parameters: metadata: A dictionary mapping metadata titles to their data
        //                       example: {"Name": "Alpha Access", "Season": "Pre-Season"}
        //
        pub fun createReward(metadata: {String: String}, supplyCap: UInt32): UInt32 {
            // Create the new Reward
            var newReward = Reward(metadata: metadata)
            let newID = newReward.rewardID;

            ChainmonstersNFT.rewardSupplies[newID] = supplyCap
            ChainmonstersNFT.numberMintedPerReward[newID] = 0

            ChainmonstersNFT.rewardDatas[newID] = newReward

            return newID
        }


		// mintReward mints a new NFT-Reward with a new ID
		// 
		pub fun mintReward(rewardID: UInt32): @NFT {
            pre {
              // check if total supply allows additional NFTs
              ChainmonstersNFT.numberMintedPerReward[rewardID] != ChainmonstersNFT.rewardSupplies[rewardID]
            }

            // Gets the number of NFTs that have been minted for this Reward
            // to use as this NFT's serial number
            let numInReward = ChainmonstersNFT.numberMintedPerReward[rewardID]!

            // Mint the new NFT
            let newReward: @NFT <- create NFT(serialNumber: numInReward + UInt32(1),
                                              rewardID: rewardID)

            // Increment the count of NFTs minted for this Reward
            ChainmonstersNFT.numberMintedPerReward[rewardID] = numInReward + UInt32(1)

            return <-newReward
		}

        pub fun borrowReward(rewardID: UInt32): &Reward {
            pre {
                ChainmonstersNFT.rewardDatas[rewardID] != nil: "Cannot borrow Reward: The Reward doesn't exist"
            }
            
            // Get a reference to the Set and return it
            // use `&` to indicate the reference to the object and type
            return &ChainmonstersNFT.rewardDatas[rewardID] as &Reward
        }


         // createNewAdmin creates a new Admin resource
        //
        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }
	}



    // -----------------------------------------------------------------------
    // ChainmonstersNFT contract-level function definitions
    // -----------------------------------------------------------------------

    // public function that anyone can call to create a new empty collection
    // This is required to receive Rewards in transactions.
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create ChainmonstersNFT.Collection()
    }

    // returns all the rewards setup in this contract
    pub fun getAllRewards(): [ChainmonstersNFT.Reward] {
        return ChainmonstersNFT.rewardDatas.values
    }

    // returns returns all the metadata associated with a specific Reward
    pub fun getRewardMetaData(rewardID: UInt32): {String: String}? {
        return self.rewardDatas[rewardID]?.metadata
    }

    // getRewardMetaDataByField returns the metadata associated with a 
    //                        specific field of the metadata
    //                        Ex: field: "Name" will return something
    //                        like "Alpha Access"
    pub fun getRewardMetaDataByField(rewardID: UInt32, field: String): String? {
        // Don't force a revert if the rewardID or field is invalid
        if let reward = ChainmonstersNFT.rewardDatas[rewardID] {
            return reward.metadata[field]
        } else {
            return nil
        }
    }


     // isRewardLocked returns a boolean that indicates if a Reward
    //                      can no longer be minted.
    // 
    // Parameters: rewardID: The id of the Set that is being searched
    //             
    //
    // Returns: Boolean indicating if the reward is locked or not
    pub fun isRewardLocked(rewardID: UInt32): Bool? {
        // Don't force a revert if the reward is invalid
        if (ChainmonstersNFT.rewardSupplies[rewardID] == ChainmonstersNFT.numberMintedPerReward[rewardID]) {

            return true
        } else {

            // If the Reward wasn't found , return nil
            return nil
        }
    }

    // returns the number of Rewards that have been minted already
    pub fun getNumRewardsMinted(rewardID: UInt32): UInt32? {
        let amount = ChainmonstersNFT.numberMintedPerReward[rewardID]

        return amount
    }



	init() {
        // Initialize contract fields
        self.rewardDatas = {}
        self.nextRewardID = 1
        self.totalSupply = 0
        self.rewardSupplies = {}
        self.numberMintedPerReward = {}

         // Put a new Collection in storage
        self.account.save<@Collection>(<- create Collection(), to: /storage/RewardCollection)

        // Create a public capability for the Collection
        self.account.link<&{RewardCollectionPublic}>(/public/RewardCollection, target: /storage/RewardCollection)

        // Put the Minter in storage
        self.account.save<@Admin>(<- create Admin(), to: /storage/ChainmonstersAdmin)

        emit ContractInitialized()
	}
}

 
