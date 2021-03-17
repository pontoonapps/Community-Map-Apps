//
//  userData.swift
//  pontoon-map
//
//  Created by Niall Fraser on 19/04/2020.
//  Copyright © 2020 PONToon Project. All rights reserved.
//

import Foundation

struct TCName: Codable {
    let first: String?
    let last: String?
}

struct TrainingCentre: Codable {
    let email: String?
    let name: TCName?
}

struct UserData: Codable {
    var role: String?
    var traingingCentres: [TrainingCentre]?
}
