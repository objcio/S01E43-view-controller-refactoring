import UIKit

public final class EpisodeCell: UITableViewCell {
    fileprivate var titleLabel = UILabel()
    fileprivate var badgeLabel = UILabel() // shown in inverted colors
    fileprivate var detailLabel1 = UILabel()
    fileprivate var detailLabel2 = UILabel()

    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(badgeLabel)
        contentView.addSubview(detailLabel1)
        contentView.addSubview(detailLabel2)
        setupLayout()
        configureSubviews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constrainEqual(contentView.layoutMarginsGuide.topAnchor)
        titleLabel.leadingAnchor.constrainEqual(contentView.layoutMarginsGuide.leadingAnchor)
        titleLabel.trailingAnchor.constrainEqual(contentView.layoutMarginsGuide.trailingAnchor)

        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.centerYAnchor.constrainEqual(detailLabel1.centerYAnchor)
        badgeLabel.leadingAnchor.constrainEqual(titleLabel.leadingAnchor)
        badgeLabel.bottomAnchor.constrainEqual(contentView.layoutMarginsGuide.bottomAnchor)
        badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

        detailLabel1.translatesAutoresizingMaskIntoConstraints = false
        detailLabel1.topAnchor.constrainEqual(titleLabel.bottomAnchor, constant: 8)
        detailLabel1.leadingAnchor.constrainEqual(badgeLabel.trailingAnchor, constant: 16)
        detailLabel1.bottomAnchor.constrainEqual(contentView.layoutMarginsGuide.bottomAnchor)

        detailLabel2.translatesAutoresizingMaskIntoConstraints = false
        detailLabel2.centerYAnchor.constrainEqual(detailLabel1.centerYAnchor)
        detailLabel2.trailingAnchor.constrainEqual(titleLabel.trailingAnchor)
    }

    private func configureSubviews() {
        contentView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        detailLabel1.font = UIFont.preferredFont(forTextStyle: .headline)
        detailLabel2.font = UIFont.preferredFont(forTextStyle: .headline)
        badgeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        badgeLabel.textAlignment = .center
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = .black
        badgeLabel.clipsToBounds = true
        badgeLabel.layer.cornerRadius = 10
    }
}

extension EpisodeCell {
    public func configure(viewModel: EpisodeViewModel) {
        titleLabel.text = viewModel.episode.title
        badgeLabel.text = viewModel.episode.subscriptionOnly ? "SUB" : "FREE"
        detailLabel1.text = viewModel.releaseDate
        detailLabel2.text = viewModel.duration
    }
}
