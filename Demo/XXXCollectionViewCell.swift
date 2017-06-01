//
//  XXXCollectionViewCell.swift
//  CHTCollectionViewWaterfallLayout+Rx
//
//  Created by 孙继刚 on 2017/5/28.
//  Copyright © 2017年 madordie. All rights reserved.
//

import UIKit

class XXXCollectionViewCell: UICollectionViewCell {

    let label = UILabel()

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if label.superview == nil {
            contentView.addSubview(label)
        }
        label.frame = CGRect(x: 0, y: 0, width: size.width, height: 100)
        return CGSize(width: size.width, height: label.frame.maxY)
    }
}

class XXXCollectionViewCellModel: CHTWaterfallListItemDefaultProtocol {

    var idx: String?

    func fillModel(for item: XXXCollectionViewCell) {
        item.backgroundColor = UIColor.gray
        item.label.text = idx
    }
}
