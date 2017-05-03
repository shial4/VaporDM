import Vapor


/** VaporDM is Vapor's direct message main object. Based on your Fluent model corresponding to DMParticipants for further integration with chat rooms and users messages.
 */
open class VaporDM<T:DMUser> {
    fileprivate let drop: Droplet?
    
    /** Default initializator with droplet.
     
    - Parameter droplet: Droplet object required to correctly set up VaporDM
     
    ```
    // Example:
     
    let drop = Droplet()
    let dm = VaporDM<User>(for: drop)
    ```
     */
    public init(for droplet: Droplet) {
        self.drop = droplet
        _ = DMController<T>(drop: droplet)
    }
}
