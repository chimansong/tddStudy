//
//  FeedItemMapper.swift
//  FeedLoaderTDDStudy
//
//  Created by MK-Mac-210 on 2022/04/27.
//

import Foundation

internal final class FeedItemMapper {
  private struct Root: Decodable {
    let items: [Item]
  }

  private struct Item: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL

    var item: FeedItem {
      return FeedItem(id: id, description: description, location: location, imageURL: image)
    }
  }

  private static var OK_200: Int { return 200 }

  internal static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
    guard response.statusCode == OK_200 else {
      return .failure(.invalidData)
    }

    do {
      let root = try JSONDecoder().decode(Root.self, from: data)
      let items = root.items.map { $0.item }
      return .success(items)
    } catch {
      return .failure(.invalidData)
    }
  }
}
