

transaction(data: [{ String: String }]) {
    prepare(acct: AuthAccount) {
        let metadataStoragePath = /storage/ChainmonstersRewardsMetadata
        let metadataPublicPath = /public/ChainmonstersRewardsMetadata
        
        // Load old data to clear the storage
        let oldData = acct.load<[{ String: String }]>(
          from: metadataStoragePath
        )
        
        acct.save(data, to: metadataStoragePath)

        acct.link<&[{ String: String }]>(
          metadataPublicPath,
          target: metadataStoragePath
        )
    }
}
