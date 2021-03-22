//
//  LoadImageCommentsDataFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Sebastian Vidrea on 19.03.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

class RemoteImageCommentsLoader {
	private let url: URL
	private let client: HTTPClient

	init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	func load() {
		client.get(from: url) { _ in }
	}
}

class LoadImageCommentsDataFromRemoteUseCaseTests: XCTestCase {

	func test_init_doesNotRequestDataFromURL() {
		let url = URL(string: "https://a-given-url.com")!
		let client = HTTPClientSpy()
		let _ = RemoteImageCommentsLoader(url: url, client: client)

		XCTAssertTrue(client.requestedURLs.isEmpty)
	}

	func test_load_requestsDataFromURL() {
		let url = URL(string: "https://a-given-url.com")!
		let client = HTTPClientSpy()
		let sut = RemoteImageCommentsLoader(url: url, client: client)

		sut.load()

		XCTAssertEqual(client.requestedURLs, [url])
	}

}
