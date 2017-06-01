//
//  PlainViewController.swift
//  CHTCollectionViewWaterfallLayout+Rx
//
//  Created by 孙继刚 on 2017/5/28.
//  Copyright © 2017年 madordie. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PlainViewController: UIViewController {

    let list = CHTWaterfallList.new(frame: CGRect.zero)
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Plain"

        view.addSubview(list)
        list.frame = view.bounds

        list.viewModel = {
            var source = [CHTWaterfallListModel]()
            for idx in 0..<10 {
                let viewModel = CHTWaterfallListModel()
                viewModel.header = {
                    let m = XXXCollectionViewHeaderModel()
                    m.idx = "\(idx) - header"
                    return m
                }()
                viewModel.items = {
                    var items = [XXXCollectionViewCellModel]()
                    for row in 0..<5 {
                        let cell = XXXCollectionViewCellModel()
                        cell.idx = "\(idx):\(row) - item"
                        items.append(cell)
                    }
                    return items
                }()
                viewModel.footer = {
                    let m = XXXCollectionViewHeaderModel()
                    m.idx = "\(idx) - footer"
                    return m
                }()
                viewModel.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                viewModel.minimumColumnSpacing = 10
                viewModel.minimumInteritemSpacing = 10
                source.append(viewModel)
            }
            return source
        }()

        list.rx.contentOffset
            .subscribe(onNext: { (offset) in
                print(offset)
            })
            .addDisposableTo(disposeBag)
    }
}
