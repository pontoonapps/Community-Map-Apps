//
//  pin.swift
//  pontoon-map
//
//  Created by Niall Fraser on 22/02/2020.
//  Copyright © 2020 PONToon Project. All rights reserved.
//

import Foundation

struct Pin: Codable {
    var id:             Int?
    var name:           String?
    var latitude:       Double?
    var longitude:      Double?
    var category:       Int?
    var description:    String?
    var phone:          String?
    var website:        String?
    var email:          String?
    var address_line_1: String?
    var address_line_2: String?
    var postcode:       String?
    var notes:          String?
    var userPin:        Bool?
    var training_centre_email: String?
}
