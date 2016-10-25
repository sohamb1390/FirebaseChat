//
//  ChatCell.swift
//  LocationChat
//
//  Created by Soham Bhattacharjee on 17/10/16.
//  Copyright © 2016 Soham Bhattacharjee. All rights reserved.
//

import UIKit

class ChatCell: UITableViewCell {

    @IBOutlet weak var lblSenderText: UILabel!
    @IBOutlet weak var lblRecieverText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        lblSenderText.layer.cornerRadius = 5.0
        lblSenderText.layer.masksToBounds = true
        lblSenderText.clipsToBounds = true
    }

    func getRandomColor() -> UIColor{
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
