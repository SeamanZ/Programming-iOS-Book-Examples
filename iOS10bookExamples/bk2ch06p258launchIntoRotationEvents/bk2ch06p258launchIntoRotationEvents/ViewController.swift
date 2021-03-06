

import UIKit

extension UIUserInterfaceSizeClass : CustomStringConvertible {
    public var description : String {
        if self == .compact {return "compact"}
        if self == .regular {return "regular"}
        return "unknown"
    }
}

extension UITraitCollection {
    open override var description : String {
        return "\(self.horizontalSizeClass) \(self.verticalSizeClass)"
    }
    open override var debugDescription : String {
        return "\(self.horizontalSizeClass) \(self.verticalSizeClass)"
    }
}

/*

I can think of various ways we can wind up launching into landscape:

* We accept any orientation, but the device happens to be in landscape at launch time

* The app (.plist) accepts only landscape

* The app (.plist) accepts any orientation, but landscape is first

* The app accepts any orientation, but the view controller restricts it to landscape

*/

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return super.supportedInterfaceOrientations
        return .landscape
    }
    
//    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController!) -> Int {
//        return Int(UIInterfaceOrientationMask.Landscape.rawValue)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationController.delegate = self
        print("viewDidLoad")
        print("viewDidLoad reports \(self.view.bounds.size)")
        print("viewDidLoad reports \(self.traitCollection)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("will appear \(self.view.bounds.size)")
    }
    
    override func viewWillLayoutSubviews() {
        print("willLayout  \(self.view.bounds.size)")
    }
    
    override func viewDidLayoutSubviews() {
        print("didLayout \(self.view.bounds.size)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("did appear \(self.view.bounds.size)")
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        print("willTransition trait", newCollection)
        super.willTransition(to: newCollection, with: coordinator)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("willTransition size", size)
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        print("trait collection did change to \(self.traitCollection)")
    }

}

/*

=== normal launch into portrait:

viewDidLoad, portrait view, portrait trait collection
(will appear)
trait collection did change
(willLayout)
(didLayout)
(did appear)

=== normal launch with device at landscape: NB this happens regardless of order in info plist!
[basically the rule seems to be if app can launch into portrait, it will]

viewDidLoad, portrait view, portrait trait collection
trait collection did change (and the others)
[visible rotation]
will transition to landscape
will transition to landscape view size
trait collection did change
did/will layout

=== app accepts only landscape:

viewDidLoad, landscape view, landscape trait collection
(will appear)
trait collection did change (and the others)
=> so, in this case, we do not start with portrait and then rotate!

=== app accepts any, but landscape is first, but device is held in portrait:
[New: just like the first case! we launch into portrait and stay there]

=== app accepts any, portrait or landscape is first (!), but view controller is landscape only, device is held in portrait or landscape:

viewDidLoad, portrait view, portrait trait
(will appear)
will transition to landscape trait collection
NO SIZE CHANGE NOTIFICATION
trait collection did change
(layout, did appear)
[and if the app then rotates 180 degrees]
will transition to same landscape size


*/

/* 
If we are in, say, navigation interface,
we do not have actual view dimensions until "will appear"
*/

/*
In navigation interface, we can get did layout more than once on rotation...
...and dimensions are not necessarily correct the first time
layout on rotation in that case is *after* the transitions/trait changes
*/

/*
I took out the navigation interface because it confuses the matter for now;
for example, we can launch into portrait even if the navigation controller delegate says no
*/

