import Vapor


/** VaporDM is Vapor's direct message main object. Based on your Fluent model corresponding to DMParticipants for further integration with chat rooms and users messages.
 */
open class VaporDM<T:DMUser> {
    /// An Droplet object on which VaporDM work
    fileprivate let drop: Droplet?
    /// Default initializator with droplet.
    ///
    /// - Parameters:
    ///   - droplet: Droplet object required to correctly set up VaporDM
    ///   - configuration: DMConfiguration object required to configure VaporDM. Default value is DMDefaultConfiguration() object
    ///```
    ///// Example:
    ///
    ///let drop = Droplet()
    ///let dm = VaporDM<User>(for: drop)
    ///```
    public init(for droplet: Droplet, configuration: DMConfiguration = DMDefaultConfiguration()) {
        self.drop = droplet
        _ = DMController<T>(drop: droplet, configuration: configuration)
    }
}
