//
//  RemoteFeedLoaderTests.swift
//  FeedLoaderTDDStudyTests
//
//  Created by MK-Mac-210 on 2022/04/19.
//

import XCTest
import FeedLoaderTDDStudy

class RemoteFeedLoaderTests: XCTestCase {

  func test_init_doesNotRequestDateFromURL() {
    let (_, client) = self.makeSUT()

    XCTAssertTrue(client.requestedURLS.isEmpty)
  }

  func test_load_requestsDataFromURL() {
    let url = URL(string: "https://a-given-url.com")!
    /* SUT == System Under Testing. System being tested. 즉 테스팅 하는 대상(object) */
    let (sut, client) = self.makeSUT(url: url)
    sut.load { _ in }

    XCTAssertEqual(client.requestedURLS, [url])
  }

  func test_init_doesNotRequestDataFromURL() {
    let url = URL(string: "https://a-given-url.com")!
    let (_, client) = self.makeSUT(url: url)
    XCTAssertTrue(client.requestedURLS.isEmpty)
  }

  func test_loadTwice_requestsDataFromURLTwice() {
    let url = URL(string: "https://a-given-url.com")!
    let (sut, client) = self.makeSUT(url: url)
    sut.load { _ in }
    sut.load { _ in }

    XCTAssertEqual(client.requestedURLS, [url, url])
  }

  func test_load_deliversErrorOnClientError() {
    let (sut, client) = self.makeSUT()
    self.expect(sut, toCompleteWith: .failture(.connectivity)) {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(with: clientError)
    }
  }

  func test_load_deliversErrorOnNon200HTTPResponse() {
    let (sut, client) = self.makeSUT()
    let samples = [199, 201, 300, 400, 500]
    samples.enumerated().forEach { index, code in
      self.expect(sut, toCompleteWith: .failture(.invalidData)) {
        let json = self.makeItemsJSON([])
        client.complete(withStatusCode: code, data: json, at: index)
      }
    }
  }

  func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
    let (sut, client) = self.makeSUT()

    self.expect(sut, toCompleteWith: .failture(.invalidData), when: {
      let invalidJSON = makeItemsJSON([])
      client.complete(withStatusCode: 200, data: invalidJSON)
    })
  }

  func test_load_deliversNoItemsOn200HTTPResponseWithEmptyList() {
    let (sut, client) = self.makeSUT()

    expect(sut, toCompleteWith: .success([])) {
      let emptyListJSON = Data("{\"items\": []}".utf8)
      client.complete(withStatusCode: 200, data: emptyListJSON)
    }
  }

  func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
    let (sut, client) = self.makeSUT()

    let item1 = self.makeItem(
      id: UUID(),
      imageURL: URL(string: "http://a-url.com")!
    )

    let item2 = self.makeItem(
      id: UUID(),
      description: "a description",
      location: "a location",
      imageURL: URL(string: "http://another-url.com")!
    )

    let items = [item1.model, item2.model]

    expect(sut, toCompleteWith: .success(items)) {
      let json = makeItemsJSON([item1.json, item2.json])
      client.complete(withStatusCode: 200, data: json)
    }
  }

  // MARK: - Helpers
  private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    trackForMemoryLeaks(sut)
    trackForMemoryLeaks(client)
    return (sut, client)
  }

  private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
    addTeardownBlock { [weak instance] in
      XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
    }
  }

  private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
    let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)

    let json = [
      "id": id.uuidString,
      "description": description,
      "location": location,
      "image": imageURL.absoluteString
    ].reduce(into: [String: Any]()) { (acc, e) in
      if let value = e.value {
        acc[e.key] = value
      }
    }

    return (item, json)
  }

  private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
    let json = ["items": items]
    return try! JSONSerialization.data(withJSONObject: json)
  }

  private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
    var capturedResult = [RemoteFeedLoader.Result]()
    sut.load { capturedResult.append($0) }
    action()
    XCTAssertEqual(capturedResult, [result], file: file, line: line)
  }

  // Stub
  private class HTTPClientSpy: HTTPClient {
    var requestedURLS: [URL] {
      return self.messages.map { $0.url }
    }

    private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
      self.messages.append((url, completion))
    }

    func complete(with error: NSError, at index: Int = 0) {
      self.messages[index].completion(.failure(error))
    }

    func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
      let response = HTTPURLResponse(url: requestedURLS[index], statusCode: code, httpVersion: nil, headerFields: nil)!
      messages[index].completion(.success(data, response))
    }

  }
}
