//
//  NoSwipeSegmentedControl.swift
//  pontoon-map
//
//  Created by Niall Fraser on 19/01/2020.
//  Copyright © 2020 PONToon Project. All rights reserved.
//

import UIKit

class NoSwipeSegmentedControl: UISegmentedControl {
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
