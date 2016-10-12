//
//  Dependencies.swift
//  Blah
//
//  Created by Brad Howes on 10/8/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

final class PassiveDependencyInjector: NSObject {
    static var singleton: PassiveDependencyInjector = PassiveDependencyInjector()

    var recordingsStore: RecordingsStoreInterface!
    var recordingActivityLogic: RecordingActivityLogicInterface!
    var userSettings: UserSettingsInterface!
    var runDataGenerator: ((UserSettingsInterface) -> RunDataInterface)!
    var dropboxController: DropboxController!

    private override init() {
        super.init()
    }
}
