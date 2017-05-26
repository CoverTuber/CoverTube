//
//  UtilityFunctions.swift
//  Cover Tube
//
//  Created by June Suh on 5/25/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import Foundation

/* Makes search bar resign first responder in sthe swipe container view controller */
func resignSearchBarFirstResponse()
{
    NotificationCenter.default.post(name: ResignSearchBarFirstResponderNotificationName,
                                    object: nil, userInfo: nil)
}

/**/
func hideMinimizedPlayerView ()
{
    NotificationCenter.default.post(name: HideMinimizedPlayerViewNotificationName,
                                    object: nil)
}

func showMinimizedPlayerView ()
{
    NotificationCenter.default.post(name: ShowMinimizedPlayerViewNotificationName,
                                    object: nil)
}


func convertToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}
