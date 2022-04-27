//
//  HTTPClient.swift
//  FeedLoaderTDDStudy
//
//  Created by MK-Mac-210 on 2022/04/27.
//

import Foundation

public enum HTTPClientResult {
  case success(Data, HTTPURLResponse)
  case failure(Error)
}

public protocol HTTPClient {
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
