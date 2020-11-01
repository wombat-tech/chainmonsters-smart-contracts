# Chainmonsters

## ToDo:

- Figure out a better naming scheme for Rewards<--->NFTs
- implement season based rewards properly
- provide full metadata overview
- add events to ReadMe

## Introduction

This repository contains the smart contracts and transactions that implement the core functionality of Chainmonsters.
This first iteration is based on the Flow Non-Fungible Token standard on Flow Blockchain (October 2020)

## What is Chainmonsters

Chainmonsters is a massive multiplayer online RPG inspired by monster catching games and our favorite SNES videogames! Realtime multiplayer, cross-platform play across Steam, mobile and consoles, and our player-driven economy truly bring digital assets to life! https://playchainmonsters.com

## Directory Structure

The directories here are organized into contracts, scripts, and transactions.

Contracts contain the source code for the Chainmonsters contracts that are deployed to Flow.

Scripts contain read-only transactions to get information about the state of someones Collection or about the state of the Chainmonsters contract.

Transactions contain the transactions that various admins and users can use to perform actions in the smart contract like creating rewards and seasons, minting NFTs, and transfering them.

contracts/ : Where the Chainmonsters related smart contracts live.
transactions/ : This directory contains all the state-changing transactions that are associated with the Chainmonsters smart contracts.
transactions/scripts/ : This contains all the read-only Cadence scripts that are used to read information from the smart contract or from a resource in account storage.

## Contract Overview

Each Chainmonsters NFT represents a Chainmon, item or cosmetic from within the game. The NFTs are grouped into seasons which usually have some overarching theme, exclusive items and rewards.
We are starting out with our Kickstarter and Pre-Season rewards.

### Kickstarter Rewards

In our Kickstarter campaign (https://www.kickstarter.com/projects/cinetek/chainmonsters) users can select several different tiers and receive multiple exclusive rewards in return. On the blockchain, each reward is represented by an NFT. Those NFTs will be minted early December once our campaign is over. Additional Pre-Season rewards (25+ NFTs!) are being distributed over time to our Closed Alpha players!

Multiple NFTs can be minted from the same reward and each receives a serial number that indicates where in the edition it was minted.

Each Reward is a resource object with roughly the following structure:

pub resource Reward {

    // global unique NFT ID
    pub let id: UInt64

    // the ID of the Reward that the NFT comes from
    pub let rewardID: UInt32

    // the place in the edition that this NFT was minted
    // Otherwise known as the serial number
    pub let serialNumber: UInt32

}
The other types that are defined in Chainmonsters are as follows:

Reward: A struct type that holds most of the metadata for the Rewards.
RewardData: A struct that contains constant information about rewards like the name, the series, the id, and such.
NFT: A resource type that is the NFT that represents the Reward a user owns. It stores its unique ID and other metadata. This is the collectible object that the users store in their accounts.
Collection: Similar to the NFTCollection resource from the NFT example, this resource is a repository for a user's Rewards. Users can withdraw and deposit from this collection and get information about the contained Rewards.
Admin: This is a resource type that can be used by admins to perform various acitions in the smart contract like starting a new season, creating a new reward, and getting a reference to an existing reward.
Metadata structs associated with rewards are stored in the main smart contract and can be queried by anyone.

The power to create new Rewards, Seasons and NFTs rests with the owner of the Admin resource.

Admins create rewards based on a Season which are stored in the main smart contract, from those rewards, NFTs can then be minted from.

Admins can end the current season which locks the ability to mint new NFTs from existing Rewards. This cannot be reversed.

Some rewards come with a fixed total supply which sets a hard cap on e.g. the Kickstarter exclusive Crystal variations.

These rules are in place to ensure the scarcity of seasons and rewards once they are no longer obtainable.

Once a user owns a Reward object, that Reward is stored directly in their account storage via their Collection object. The collection object contains a dictionary that stores the Rewards and gives utility functions to move them in and out and to read data about the collection and its Rewardss.

## Chainmonsters Events

The smart contract and its various resources will emit certain events that show when specific actions are taken, like transferring an NFT. This is a list of events that can be emitted, and what each event means.

## Chainmonsters Marketplace

An in-game marketplace is in the works and will be published here once available.
