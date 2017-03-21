import UIKit

public final class ReadableContentViewController: UIViewController {
    private let child: UIViewController

    public init(_ child: UIViewController) {
        self.child = child
        super.init(nibName: nil, bundle: nil)
        self.title = child.title
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(child)
        view.addSubview(child.view)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        child.view.constrainEdges(to: view.readableContentGuide)
        child.didMove(toParentViewController: self)
    }
}
