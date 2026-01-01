// File: Core/Remote/StreamingAppLaunching.swift

import Foundation
import Combine

public protocol StreamingAppLaunching {
    var streamingApps: Set<StreamingApp> { get }
    var isStreamingAppsLoaded: Bool { get }
    var streamingAppsPublisher: AnyPublisher<Set<StreamingApp>, Never> { get }
    var streamingAppsLoadedPublisher: AnyPublisher<Bool, Never> { get }
    func launchStreamingApp(_ app: StreamingApp) async throws
}
