//
//  ImageCommentsMapperTests.swift
//  EssentialFeedTests
//
//  Created by Sebastian Vidrea on 19.03.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

class ImageCommentsMapperTests: XCTestCase {
	func test_load_deliversErrorOnNon200HTTPResponse() throws {
		let json = makeCommentsJSON([])
		let samples = [199, 201, 300, 400, 500]

		try samples.forEach { code in
			XCTAssertThrowsError(
				try ImageCommentsMapper.map(json, from: HTTPURLResponse(statusCode: code))
			)
		}
	}

	func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
		let invalidJSON = Data("invalid json".utf8)

		XCTAssertThrowsError(
			try ImageCommentsMapper.map(invalidJSON, from: HTTPURLResponse(statusCode: 200))
		)
	}

	func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() throws {
		let emptyListJSON = makeCommentsJSON([])

		let result = try ImageCommentsMapper.map(emptyListJSON, from: HTTPURLResponse(statusCode: 200))

		XCTAssertEqual(result, [])
	}

	func test_load_deliversItemsOn200HTTPResponseWithJSONItems() throws {
		let item1 = makeItem(
			id: UUID(),
			message: "a message",
			date: "2020-05-20T11:24:59+0000",
			username: "a username"
		)

		let item2 = makeItem(
			id: UUID(),
			message: "another message",
			date: "2020-05-19T14:23:53+0000",
			username: "another username"
		)

		let json = makeCommentsJSON([item1.json, item2.json])

		let result = try ImageCommentsMapper.map(json, from: HTTPURLResponse(statusCode: 200))

		XCTAssertEqual(result, [item1.model, item2.model])
	}

	// MARK: - Helpers
	lazy var iso8601DateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateFormat = "yyy-MM-dd'T'HH:mm:ssZ"
		return df
	}()

	private func makeItem(id: UUID, message: String, date: String, username: String) -> (model: ImageComment, json: [String: Any]) {
		let author = ImageCommentAuthor(username: username)
		let createdAt = iso8601DateFormatter.date(from: date)!
		let item = ImageComment(id: id, message: message, createdAt: createdAt, author: author)

		let authorJson: [String: Any] = [
			"username": author.username
		]

		let json: [String: Any] = [
			"id": item.id.uuidString,
			"message": item.message,
			"created_at": date,
			"author": authorJson
		].compactMapValues { $0 }

		return (item, json)
	}

	private func makeCommentsJSON(_ items: [[String: Any]]) -> Data {
		let json = ["items": items]
		return try! JSONSerialization.data(withJSONObject: json)
	}
}
