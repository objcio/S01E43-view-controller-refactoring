import UIKit

final public class EpisodeDetailViewController: UIViewController {
    let viewModel: EpisodeViewModel
    var content: [ContentElement] = []
    let scrollView = UIScrollView()
    let stack = UIStackView()
    let thumbnail = UIImageView()

    public init(viewModel: EpisodeViewModel, didTapPlay: @escaping (Episode) -> ()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = viewModel.episode.title
        let components: [ContentElement?] = [
            ContentElement(text: viewModel.episode.title, style: .title2, alignment: .center),
            .custom(thumbnail),
            ContentElement(text: viewModel.synopsis),
            .custom(UIStackView(axis: .horizontal, spacing: 16, content: [
                ContentElement(text: viewModel.subscriptionOnlyText),
                ContentElement(text: viewModel.releaseDate, alignment: .center),
                ContentElement(text: viewModel.duration, alignment: .right),
            ])),
            .button(title: viewModel.playButtonTitle, callback: { didTapPlay(viewModel.episode) }),
            viewModel.isLoginButtonVisible ? .button(title: "Login", callback: { [unowned self] in self.presentAlert(message: "Not implemented yet.") }) : nil
        ]
        content = components.flatMap { $0 }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadView() {
        view = UIView()
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constrainEqual(view.layoutMarginsGuide.topAnchor)
        scrollView.leadingAnchor.constrainEqual(view.layoutMarginsGuide.leadingAnchor)
        scrollView.trailingAnchor.constrainEqual(view.layoutMarginsGuide.trailingAnchor)
        scrollView.bottomAnchor.constrainEqual(view.layoutMarginsGuide.bottomAnchor)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.topAnchor.constrainEqual(scrollView.layoutMarginsGuide.topAnchor)
        stack.leadingAnchor.constrainEqual(scrollView.layoutMarginsGuide.leadingAnchor)
        stack.trailingAnchor.constrainEqual(scrollView.layoutMarginsGuide.trailingAnchor)

        stack.axis = .vertical
        stack.spacing = 40
        stack.layoutMargins = UIEdgeInsets(top: 60, left: 500, bottom: 200, right: 500)
        stack.isLayoutMarginsRelativeArrangement = true

        thumbnail.contentMode = .scaleAspectFit
        thumbnail.heightAnchor.constraint(equalToConstant: 400).isActive = true
        thumbnail.image = UIImage(named: "placeholder")
        viewModel.loadThumbnail { [weak self] image in self?.thumbnail.image = image }

        for element in content {
            stack.addArrangedSubview(element.view)
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: view.bounds.maxX, height: max(view.bounds.maxY, stack.frame.maxY))
    }
}
