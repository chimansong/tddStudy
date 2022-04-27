//
//  RemoteeedLoader.swift
//  FeedLoaderTDDStudy
//
//  Created by MK-Mac-210 on 2022/04/20.
//

import Foundation

public final class RemoteFeedLoader {
  private let url: URL
  private let client: HTTPClient

  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }

  public enum Result: Equatable {
    case success([FeedItem])
    case failure(Error)
  }

  public init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }

  public func load(completion: @escaping (Result) -> Void) {
    self.client.get(from: url) { result in
      switch result {
      case let .success(data, response):
        completion(FeedItemMapper.map(data, from: response))
      case .failure:
        completion(.failure(.connectivity))
      }
    }
  }
}
