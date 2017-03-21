//
//  VideoDownloader.swift
//  VideoDownloads
//
//  Created by Chris Eidhof on 03/11/2016.
//  Copyright © 2016 objc.io. All rights reserved.
//

import Foundation

struct DownloadState {
    enum State {
        case pausedByUser
        case waitingForConnection
        case inProgress
        case cancelled
        case finished
    }
    
    let url: URL
    var state: State = .pausedByUser
    var progress: Double = 0
}

final class DownloadManager: NSObject, URLSessionDownloadDelegate {
    var stateChanged: ((DownloadState) -> ())?
    var saveDownload: ((URL, URL) -> ())? // original, tempFile
    
    private var _session: URLSession?
    private var session: URLSession {
        return _session!
    }
    private var states: [URLSessionTask: DownloadState] = [:]
    
    private func task(for url: URL) -> URLSessionTask? {
        return states.first { key, value in
            return value.url == url
        }?.0
    }
    
    private func modifyState(for task: URLSessionTask, transform: (inout DownloadState) -> ()) {
        transform(&states[task]!)
        stateChanged?(states[task]!)
    }
    
    override init() {
        super.init()
        // This creates a reference cycle because the delegate is strongly retained. not a problem in practice because VideoDownloader is a singleton.
        let configuration = URLSessionConfiguration.background(withIdentifier: "io.objc.background")
        configuration.allowsCellularAccess = false
        _session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func start(url: URL) {
        let task = self.task(for: url) ?? session.downloadTask(with: url)
        let progress = states[task]?.progress ?? 0
        states[task] = DownloadState(url: url, state: .inProgress, progress: progress)
        task.resume()
    }
    
    func cancel(url: URL) {
        guard let task = task(for: url) else {
            fatalError("There should be a task")
        }
        task.cancel()
        modifyState(for: task) {
            $0.state = .cancelled
        }
        states[task] = nil
    }
    
    func pause(url: URL) {
        guard let task = task(for: url) else {
            fatalError("There should be a task")
        }
        task.suspend()
        modifyState(for: task) {
            $0.state = .pausedByUser
        }
    }
    
    // delegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        modifyState(for: downloadTask) {
            $0.progress = 1
            $0.state = .finished
        }
        let state = states[downloadTask]!
        saveDownload?(state.url, location)
        states[downloadTask] = nil
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        modifyState(for: downloadTask) { state in
            state.progress = progress
            state.state = .inProgress
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let _ = error else { return }
        modifyState(for: task) { state in
            state.state = .waitingForConnection
        }
    }
}
