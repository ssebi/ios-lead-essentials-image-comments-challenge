//
//  ImageCommentsUIIntegrationTests+Assertions.swift
//  EssentialAppTests
//
//  Created by Sebastian Vidrea on 09.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed
import EssentialFeediOS

extension ImageCommentsUIIntegrationTests {
	func assertThat(_ sut: ListViewController, isRendering imageComments: [ImageComment], file: StaticString = #filePath, line: UInt = #line) {
		sut.view.enforceLayoutCycle()

		guard sut.numberOfRenderedImageCommentViews() == imageComments.count else {
			return XCTFail("Expected \(imageComments.count) image comments, got \(sut.numberOfRenderedImageCommentViews()) instead.", file: file, line: line)
		}

		let imageComments = ImageCommentsPresenter.map(imageComments).imageComments

		imageComments.enumerated().forEach { index, imageComment in
			assertThat(sut, hasViewConfiguredFor: imageComment, at: index, file: file, line: line)
		}

		executeRunLoopToCleanUpReferences()
	}

	func assertThat(_ sut: ListViewController, hasViewConfiguredFor viewModel: ImageCommentViewModel, at index: Int, file: StaticString = #filePath, line: UInt = #line) {
		let view = sut.imageCommentView(at: index)

		guard let cell = view as? ImageCommentCell else {
			return XCTFail("Expected \(ImageCommentCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
		}

		XCTAssertEqual(cell.messageText, viewModel.message, "messageText at index \(index)", file: file, line: line)
		XCTAssertEqual(cell.userNameText, viewModel.username, "userNameText at index \(index)", file: file, line: line)
		XCTAssertEqual(cell.createdAtText, viewModel.createdAt, "createdAtText at index \(index)", file: file, line: line)
	}

	private func executeRunLoopToCleanUpReferences() {
		RunLoop.current.run(until: Date())
	}
}
