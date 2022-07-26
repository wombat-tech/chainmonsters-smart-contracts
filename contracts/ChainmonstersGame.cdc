
pub contract ChainmonstersGame {

  /**
   * Contract events
   */

  pub event ContractInitialized()
  

  pub event GameEvent(eventID: UInt32, playerID: String?)


  /**
   * Contract-level fields
   */



  /**
   * Structs
   */

  

  

  // Whoever owns an admin resource can emit game events and create new admin resources
  pub resource Admin {

    pub fun emitGameEvent(eventID: UInt32?, playerID: String?) {
      emit GameEvent(eventID: eventID, playerID: playerID)
    }


    // createNewAdmin creates a new Admin resource
    pub fun createNewAdmin(): @Admin {
        return <-create Admin()
    }
  }

  /**
   * Contract-level functions
   */

  

  init() {

    self.account.save<@Admin>(<- create Admin(), to: /storage/chainmonstersGameAdmin)

    emit ContractInitialized()
  }
}
