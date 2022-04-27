//
//  FeedLoader.swift
//  FeedLoaderTDDStudy
//
//  Created by MK-Mac-210 on 2022/04/19.
//

import Foundation

enum LoadFeedResult {
  case success([FeedItem])
  case error(Error)
}

protocol FeedLoader {
  func load(completion: @escaping (LoadFeedResult) -> Void)
}
