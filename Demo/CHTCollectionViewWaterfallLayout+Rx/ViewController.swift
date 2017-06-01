//
//  ViewController.swift
//  CHTCollectionViewWaterfallLayout+Rx
//
//  Created by 孙继刚 on 2017/4/8.
//  Copyright © 2017年 madordie. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    struct Static {
        static let cellIdentifier = "ViewController.Static.cellIdentifier"
    }

    let source = [(title: "plain style ->", vc: { PlainViewController() }),
                  (title: "group style ->", vc: { GroupViewController() })]
        as [(title: String, vc: () -> UIViewController)]

    let list = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        title = "Main"

        view.addSubview(list)
        list.frame = view.bounds
        list.register(UITableViewCell.self, forCellReuseIdentifier: Static.cellIdentifier)
        list.delegate = self
        list.dataSource = self
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Static.cellIdentifier,
                                                 for: indexPath)
        cell.textLabel?.text = source[indexPath.row].title
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
        navigationController?.pushViewController(source[indexPath.row].vc(), animated: true)
    }
}

