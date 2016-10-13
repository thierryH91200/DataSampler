//
//  RecordingsTableViewController
//  Blah
//
//  Created by Brad Howes on 9/14/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import CoreData
import JSQCoreDataKit

protocol RecordingsStoreInterface {
    var stack: CoreDataStack? { get }

    var isReady: Bool { get }

    func cannedFetchRequest(name: String) -> NSFetchedResultsController<Recording>?
    func newRunData() -> RunDataInterface
    func newRecording() -> Recording?
    func save()
}

/** 
 Manager of the Core Data stack for recordings.
 */
final class RecordingsStore : NSObject, RecordingsStoreInterface {

    private let userSettings: UserSettingsInterface
    private let runDataFactory: RunDataInterface.FactoryType
    private(set) var stack: CoreDataStack?
    private(set) var isReady: Bool

    init(userSettings: UserSettingsInterface, runDataFactory: @escaping RunDataInterface.FactoryType) {
        self.userSettings = userSettings
        self.runDataFactory = runDataFactory
        self.isReady = false

        super.init()
        Logger.log("RecordingsStore.init")
        let model = CoreDataModel(name: "RecordingModel")
        let factory = CoreDataStackFactory(model: model)
        factory.createStack { (result: StackResult) -> Void in
            switch result {
            case .success(let stack):
                Logger.log("created Core Data stack")
                self.stack = stack
                self.isReady = true
                RecordingsStoreNotification.post(recordingStore: self)

            case .failure(let err):
                Logger.log("*** failed to create Core Data stack: \(err)")
                assertionFailure("Error creating stack: \(err)")
            }
        }
    }

    func cannedFetchRequest(name: String) -> NSFetchedResultsController<Recording>? {
        guard let mainContext = self.stack?.mainContext else {
            Logger.log("*** RecordingsStore.init: nil stack")
            return nil
        }

        let fetcher = NSFetchedResultsController(fetchRequest: Recording.fetchRequest,
                                                 managedObjectContext: mainContext,
                                                 sectionNameKeyPath: nil, cacheName: nil)
        Logger.log("fetcher: \(fetcher)")
        return fetcher
    }

    func newRunData() -> RunDataInterface {
        return runDataFactory(userSettings)
    }

    func newRecording() -> Recording? {
        Logger.log("creating new recording")
        guard let mainContext = stack?.mainContext else {
            Logger.log("*** RecordingsStore.newRecording: nil stack")
            return nil
        }
        return Recording(context: mainContext, userSettings: userSettings, runData: newRunData())
    }

    func save() {
        guard let mainContext = stack?.mainContext else {
            Logger.log("*** RecordingsStore.save: nil stack")
            return
        }
        Logger.log("saving main context")
        saveContext(mainContext) { Logger.log("savedContext: \($0)") }
    }

    private func delete(recording: Recording) {
        guard let stack = self.stack else { return }
        stack.mainContext.performAndWait {
            self.stack?.mainContext.delete(recording)
        }
        saveContext(stack.mainContext)
    }
}