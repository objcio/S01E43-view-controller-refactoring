//
//  StandardViewControllers.swift
//  Videos
//
//  Created by Florian on 13/04/16.
//  Copyright © 2016 Chris Eidhof. All rights reserved.
//

import UIKit

// Idea from http://www.thedotpost.com/2016/01/ayaka-nonaka-going-swift-and-beyond-first-wave-swift

public protocol LoadingViewDelegate: class {
    func willAddContent()
    func didAddContent()
}

public final class LoadingView: UIView {
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
    weak var delegate: LoadingViewDelegate?
    
    public init<A>(load: (_ callback: @escaping (A) -> ()) -> (), build: @escaping (A) -> UIView) {
        super.init(frame: .zero)

        spinner.startAnimating()
        backgroundColor = UIColor.black
        addSubview(spinner)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.center(inView: self)
        layoutMargins = UIEdgeInsets()

        load { [weak self] data in
            self?.show(build(data))
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    public func show(_ content: UIView) {
        spinner.stopAnimating()
        delegate?.willAddContent()
        addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.constrainEdges(toMarginOf: self)
        delegate?.didAddContent()
    }

}

public final class LoadingViewController: UIViewController, LoadingViewDelegate {
    var loadingView: LoadingView?
    var contentViewController: UIViewController?
    
    init<A>(load: (_ callback: @escaping (A) -> ()) -> (), build: @escaping (A) -> UIViewController) {
        super.init(nibName: nil, bundle: nil)
        loadingView = LoadingView(load: load, build: { [weak self] a in
            let viewController = build(a)
            self?.contentViewController = viewController
            return viewController.view
        })
        loadingView?.delegate = self
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let loadingView = loadingView else { fatalError("needs loadingView") }
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.topAnchor.constrainEqual(view.topAnchor)
        loadingView.leadingAnchor.constrainEqual(view.leadingAnchor)
        loadingView.trailingAnchor.constrainEqual(view.trailingAnchor)
        loadingView.bottomAnchor.constrainEqual(bottomLayoutGuide.topAnchor)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func willAddContent() {
        guard let contentViewController = contentViewController else { fatalError("needs to have contentViewController") }
        addChildViewController(contentViewController)
    }
    
    public func didAddContent() {
        guard let contentViewController = contentViewController else { fatalError("needs to have contentViewController") }
        contentViewController.didMove(toParentViewController: self)
        self.title = contentViewController.title

    }
}

public enum LoadType {
    case regular
    case forceReload
}

public final class TableViewController<Item, Cell: UITableViewCell>: UITableViewController {
    var items: [Item] {
        didSet {
            tableView.reloadData()
        }
    }
    
    let cellIdentifier = "CellIdentifier"
    let configureCell: (Cell, Item) -> ()
    let estimatedRowHeight: CGFloat
    public var didSelect: ((Item) -> ())?
    public var didTapAccessory: ((Item) -> ())?
    
    public typealias Reload = (LoadType, @escaping ([Item]?) -> ()) -> ()
    let loadData: Reload?
    
    /// Creates an instance showing `items`.
    ///
    /// - Parameter loadData: function that gets called after initialization and on pull to refresh. Make sure to call `endLoading` when loading has completed.
    ///
    /// - Note: the table view will only have a refresh control if you provide `loadData`.
    public init(style: UITableViewStyle = .plain, title: String, items: [Item], estimatedRowHeight: CGFloat = 44, loadData: Reload? = nil, configureCell: @escaping (Cell, Item) -> ()) {
        self.items = items
        self.configureCell = configureCell
        self.estimatedRowHeight = estimatedRowHeight
        self.loadData = loadData
        super.init(style: style)
        self.title = title
        tableView.register(Cell.self, forCellReuseIdentifier: cellIdentifier)
        #if os(iOS)
            addRefreshControlIfNeeded()
            refreshControl?.beginRefreshing()
        #endif
        reload(.regular)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Use self-sizing cells
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    private func addRefreshControlIfNeeded() {
        guard loadData != nil else { return }
        #if os(iOS)
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(startRefresh), for: .valueChanged)
        #endif
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! Cell
        configureCell(cell, items[indexPath.row])
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelect?(items[indexPath.row])
    }
    
    public override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        didTapAccessory?(items[indexPath.row])
    }
    
    @objc private func startRefresh(_ sender: AnyObject) {
        reload(.forceReload)
    }
    
    private func reload(_ type: LoadType) {
        loadData?(type) { [weak self] data in
            if let data = data {
                self?.items = data
            }
            #if os(iOS)
                self?.refreshControl?.endRefreshing()
            #endif
        }
    }
}

