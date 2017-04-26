import Vapor

open class VaporDM {
    fileprivate let drop: Droplet?
    
    public init<T:DMUser>(for droplet: Droplet, withUser model: T.Type) {
        self.drop = droplet
        _ = DMController(drop: droplet, model: model)
    }
}
