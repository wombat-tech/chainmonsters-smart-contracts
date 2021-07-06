import FlowStorageFees from "../../contracts/lib/FlowStorageFees.cdc"

pub fun main(address: Address) {
    let account = getAccount(address)

    log("Storage Used")
    log(account.storageUsed)

    log("Storage Capacity")
    log(account.storageCapacity)

    log("Storage Capacity (MB)")
    log(FlowStorageFees.calculateAccountCapacity(address))
    
    log("Storage Left")
    let storageLeft = Int64(account.storageCapacity) - Int64(account.storageUsed)
    log(storageLeft)
    
    log("Storage Left (MB)")
    let storageLeftMB = UFix64(storageLeft) * 0.000001
    log(storageLeftMB)
    
    if (storageLeft < 0) {
        log("Storage Left FLOW cost")
        log(FlowStorageFees.storageCapacityToFlow(UFix64(-storageLeft)))
    }

    log("--------")
    
    log("Storage MB per FLOW")
    log(FlowStorageFees.storageMegaBytesPerReservedFLOW)

    log("total balance")
    log(account.balance)
    
    log("available balance")
    log(account.availableBalance)
}
 