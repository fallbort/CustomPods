//
//  AlbumPickerViewController.swift
//  AnyImageKit
//
//  Created by 刘栋 on 2019/9/16.
//  Copyright © 2019-2021 AnyImageProject.org. All rights reserved.
//

import UIKit

private let rowHeight: CGFloat = 80

public protocol AlbumPickerViewControllerDelegate: AnyObject {
    
    func albumPicker(_ picker: AlbumPickerViewController, didSelected album: Album)
    func albumPickerWillDisappear(_ picker: AlbumPickerViewController)
}

public final class AlbumPickerViewController: AnyImageViewController {
    
    public weak var delegate: AlbumPickerViewControllerDelegate?
    public var album: Album?
    public var albums = [Album]()
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.registerCell(AlbumCell.self)
        view.backgroundColor = manager.options.theme.backgroundColor
        view.separatorStyle = .none
        view.dataSource = self
        view.delegate = self
        return view
    }()
    
    public let manager: PickerManager
    
    public init(manager: PickerManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeNotifications()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        addNotifications()
        updatePreferredContentSize(with: traitCollection)
        setupView()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.albumPickerWillDisappear(self)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToCurrentAlbum()
    }
    
    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        updatePreferredContentSize(with: newCollection)
    }
    
    public func reloadData() {
        tableView.reloadData()
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}

// MARK: - Target
extension AlbumPickerViewController {
    
    @objc private func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func orientationDidChangeNotification(_ sender: Notification) {
        // TODO: Fix orientation change
        if UIDevice.current.userInterfaceIdiom == .pad {
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - Private
extension AlbumPickerViewController {
    
    private func addNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChangeNotification(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.snp.edges)
        }
    }
    
    private func scrollToCurrentAlbum() {
        if let album = album, let index = albums.firstIndex(of: album) {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        }
    }
    
    private func updatePreferredContentSize(with traitCollection: UITraitCollection) {
        let screenSize = ScreenHelper.mainBounds.size
        let preferredMaxHeight = floor(screenSize.height*(2.0/3.0))
        let presentingViewController = (self.presentingViewController as? ImagePickerController)?.topViewController
        let preferredWidth = presentingViewController?.view.bounds.size.width ?? screenSize.width
        if albums.isEmpty {
            preferredContentSize = CGSize(width: preferredWidth, height: preferredMaxHeight)
        } else {
            let height = CGFloat(albums.count) * rowHeight
            let preferredHeight = min(height, preferredMaxHeight)
            preferredContentSize = CGSize(width: preferredWidth, height: preferredHeight)
        }
    }
}

// MARK: - UITableViewDataSource
extension AlbumPickerViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(AlbumCell.self, for: indexPath)
        let album = albums[indexPath.row]
        cell.setContent(album, manager: manager)
        cell.accessoryType = self.album == album ? .checkmark : .none
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AlbumPickerViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let album = albums[indexPath.row]
        delegate?.albumPicker(self, didSelected: album)
        dismiss(animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
}
