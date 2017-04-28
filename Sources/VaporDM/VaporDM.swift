import Vapor

open class VaporDM<T:DMUser> {
    fileprivate let drop: Droplet?
    
    public init(for droplet: Droplet) {
        self.drop = droplet
        _ = DMController<T>(drop: droplet)
    }
}
