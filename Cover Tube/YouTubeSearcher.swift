//
//  YouTubeSearcher.swift
//  Cover Tube
//
//  Created by June Suh on 5/6/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import Foundation

/* code from https://github.com/Igor-Palaguta/YoutubeEngine */
import YoutubeEngine
import ReactiveSwift

let _defaultEngine: Engine = {
    let engine = Engine(.key("AIzaSyCgwWIve2NhQOb5IHMdXxDaRHOnDrLdrLg"))
    engine.logEnabled = true
    return engine
}()

extension Engine {
    static var defaultEngine: Engine {
        return _defaultEngine
    }
}

final class YoutubeViewModel {
    let keyword = MutableProperty("")
}
