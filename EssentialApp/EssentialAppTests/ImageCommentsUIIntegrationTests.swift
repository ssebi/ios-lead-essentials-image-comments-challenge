//
//  ImageCommentsUIIntegrationTests.swift
//  EssentialFeediOSTests
//
//  Created by Sebastian Vidrea on 02.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialApp
import EssentialFeed
import EssentialFeediOS

final class ImageCommentsUIIntegrationTests: XCTestCase {
	func test_imageCommentsView_hasTitle() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.title, localized("IMAGE_COMMENTS_TITLE"))
	}

	func test_loadImageCommentsActions_requestImageCommentsFromLoader() {
		let (sut, loader) = makeSUT()
		XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view is loaded")

		sut.loadViewIfNeeded()
		XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view is loaded")

		sut.simulateUserInitiatedImageCommentsReload()
		XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user initiates a load")

		sut.simulateUserInitiatedImageCommentsReload()
		XCTAssertEqual(loader.loadCallCount, 3, "Expected a third loading request once user initiates another load")
	}

	func test_loadingImageCommentsIndicator_isVisibleWhileLoadingImageComments() {
		let (sut, loader) = makeSUT()

		sut.loadViewIfNeeded()
		XCTAssertEqual(sut.isShowingLoadingIndicator, true, "Expected loading indicator once view is loaded")

		loader.completeImageCommentsLoading(at: 0)
		XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected no loading indicator once loading is completed successfully")

		sut.simulateUserInitiatedImageCommentsReload()
		XCTAssertEqual(sut.isShowingLoadingIndicator, true, "Expected loading indicator once user initiates a reload")

		loader.completeImageCommentsLoadingWithError(at: 1)
		XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected no loading indicator once user initiated loading completed with error")
	}

	func test_loadImageCommentsCompletion_rendersSuccessfullyLoadedImageComments() {
		let imageComment0 = makeImageComment(message: "a message", authorName: "a user", createdAt: Date())
		let imageComment1 = makeImageComment(message: "another message", authorName: "another user", createdAt: Date())
		let imageComment2 = makeImageComment(message: "yet another message", authorName: "yet another user", createdAt: Date())
		let (sut, loader) = makeSUT()

		sut.loadViewIfNeeded()
		assertThat(sut, isRendering: [])

		loader.completeImageCommentsLoading(with: [imageComment0], at: 0)
		assertThat(sut, isRendering: [imageComment0])

		sut.simulateUserInitiatedImageCommentsReload()
		loader.completeImageCommentsLoading(with: [imageComment0, imageComment1, imageComment2], at: 1)
		assertThat(sut, isRendering: [imageComment0, imageComment1, imageComment2])
	}

	func test_loadImageCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() {
		let imageComment0 = makeImageComment(message: "a message", authorName: "a user", createdAt: Date())
		let (sut, loader) = makeSUT()

		sut.loadViewIfNeeded()
		loader.completeImageCommentsLoading(with: [imageComment0], at: 0)
		assertThat(sut, isRendering: [imageComment0])

		sut.simulateUserInitiatedImageCommentsReload()
		loader.completeImageCommentsLoadingWithError(at: 1)
		assertThat(sut, isRendering: [imageComment0])
	}

	func test_loadImageCommentsCompletion_rendersErrorMessageOnErrorUntilNextReload() {
		let (sut, loader) = makeSUT()

		sut.loadViewIfNeeded()
		XCTAssertEqual(sut.errorMessage, nil)

		loader.completeImageCommentsLoadingWithError(at: 0)
		XCTAssertEqual(sut.errorMessage, localized("IMAGE_COMMENTS_CONNECTION_ERROR"))

		sut.simulateUserInitiatedImageCommentsReload()
		XCTAssertEqual(sut.errorMessage, nil)
	}

	func test_loadImageCommentsCompletion_rendersRelativeFormattedDate() {
		let oneHourAgo = Date().addingTimeInterval(-3600)
		let (sut, loader) = makeSUT()

		sut.loadViewIfNeeded()

		loader.completeImageCommentsLoading(with: [makeImageComment(message: "a message", authorName: "an author", createdAt: oneHourAgo)], at: 0)

		let view = sut.imageCommentView(at: 0)
		guard let cell = view as? ImageCommentCell else {
			return XCTFail("Expected \(ImageCommentCell.self) instance, got \(String(describing: view)) instead")
		}

		XCTAssertEqual(cell.createdAtText, RelativeDateTimeFormatter().localizedString(for: oneHourAgo, relativeTo: Date()))
	}

	func test_imageCommentsView_cancelsImageCommentsRequestWhenUserNavigatesBack() {
		let (sut, loader) = makeSUT()

		sut.loadViewIfNeeded()
		XCTAssertEqual(loader.cancelledImageCommentsCompletions.count, 0)

		sut.simulateViewDidDisappear()
		XCTAssertEqual(loader.cancelledImageCommentsCompletions.count, 1)
	}

	func test_imageCommentsView_doesNotRenderImageCommentWhenNoLongerVisible() {
		let (sut, loader) = makeSUT()
		sut.loadViewIfNeeded()
		loader.completeImageCommentsLoading(with: [makeImageComment()])

		let view = sut.simulateImageCommentNotVisible(at: 0)

		XCTAssertNil(view?.messageText, "Expected no rendered message text when the view is no longer visible")
		XCTAssertNil(view?.authorNameText, "Expected no rendered author name text when the view is no longer visible")
		XCTAssertNil(view?.createdAtText, "Expected no rendered created at text when the view is no longer visible")
	}

	func test_loadImageCommentsCompletion_dispatchesFromBackgroundToMainThread() {
		let (sut, loader) = makeSUT()
		sut.loadViewIfNeeded()

		let exp = expectation(description: "Wait for backgorund queue")
		DispatchQueue.global().async {
			loader.completeImageCommentsLoading()
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1.0)
	}

	// MARK: - Helpers

	private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: ImageCommentsViewController, loader: LoaderSpy) {
		let loader = LoaderSpy()
		let sut = ImageCommentsUIComposer.imageCommentsComposedWith(imageCommentsLoader: loader.loadPublisher())
		trackForMemoryLeaks(loader, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, loader)
	}

	private func makeImageComment(message: String = "a message", authorName: String = "a user", createdAt: Date = Date()) -> ImageComment {
		ImageComment(id: UUID(), message: message, createdAt: createdAt, author: ImageCommentAuthor(username: authorName))
	}
}
