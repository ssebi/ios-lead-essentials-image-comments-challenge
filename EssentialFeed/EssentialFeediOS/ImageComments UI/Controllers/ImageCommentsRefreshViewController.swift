//
//  ImageCommentsRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Sebastian Vidrea on 03.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit
import EssentialFeed

final class ImageCommentsRefreshViewController: NSObject, ImageCommentsLoadingView {
	private(set) lazy var view = loadView(UIRefreshControl())

	private let presenter: ImageCommentsPresenter

	init(presenter: ImageCommentsPresenter) {
		self.presenter = presenter
	}

	@objc func refresh() {
		presenter.loadImageComments()
	}

	func display(isLoading: Bool) {
		if isLoading {
			view.beginRefreshing()
		} else {
			view.endRefreshing()
		}
	}

	private func loadView(_ view: UIRefreshControl) -> UIRefreshControl {
		view.addTarget(self, action: #selector(refresh), for: .valueChanged)
		return view
	}
}
