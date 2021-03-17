//
//  UserTableViewCell.swift
//  pontoon-map
//
//  Created by Niall Fraser on 26/04/2020.
//  Copyright © 2020 PONToon Project. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    @IBOutlet weak var pinVisible: UISwitch!
    
    var storedFinalCallback: () -> Void = { }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        pinVisible.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setPinVisible(_ val: Bool, finalCallback: @escaping () -> Void ) {
        storedFinalCallback = finalCallback
        pinVisible.setOn(val, animated: false)
    }
    
    @objc func switchChanged() {
        storedFinalCallback()
    }
    
}
