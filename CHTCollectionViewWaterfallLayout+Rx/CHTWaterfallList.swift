//
//  CHTWaterfallList.swift
//  CHTWaterfallList
//
//  Created by 孙继刚 on 2017/5/4.
//  Copyright © 2017年 madordie. All rights reserved.
//

import UIKit

protocol CHTWaterfallListItemDefaultProtocol: CHTWaterfallListItemProtocol {
    associatedtype ItemType: UICollectionReusableView

    func fillModel(for item: ItemType)
}

extension CHTWaterfallListItemDefaultProtocol {
    var identifa: String { return  NSStringFromClass(ItemType.self)}
    var newItem: AnyObject { return ItemType() }
    var registClass: AnyClass { return ItemType.self }
    func fillModel(for item: UICollectionReusableView) {
        guard let item = item as? ItemType else { return }
        fillModel(for: item)
    }
}

protocol CHTWaterfallListItemProtocol {
    var identifa: String { get }
    var newItem: AnyObject { get }
    var registClass: AnyClass { get }
    func fillModel(for item: UICollectionReusableView)
}

class CHTWaterfallListModel: NSObject {

    var identifier = ""

    var sectionInset = UIEdgeInsets.zero

    var minimumColumnSpacing = 0.0

    var minimumInteritemSpacing = 0.0

    var columnCount = 2

    var header: CHTWaterfallListItemProtocol?

    var items = [CHTWaterfallListItemProtocol]()

    var footer: CHTWaterfallListItemProtocol?
}

class CHTWaterfallList: UICollectionView {

    var viewModel = [CHTWaterfallListModel]() {
        didSet { registerViewModels(); reloadData() }
    }

    class func new(frame: CGRect) -> CHTWaterfallList {
        let layout = CHTWaterfallLayout()
        return CHTWaterfallList(frame: frame, collectionViewLayout: layout)
    }

    internal override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setup()
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("use new() please")
    }

//    fileprivate let disposeBag = DisposeBag()
    fileprivate var calculateHeightCache = NSCache<AnyObject, UICollectionReusableView>()
}

// MARK: - setup
fileprivate extension CHTWaterfallList {

    func setup() {
        alwaysBounceVertical = true
        backgroundColor = UIColor.white
        dataSource = self

        watefallLayout?.getColumnCountForSection = { [weak self] (idx) in
            guard let _self = self else { return 0 }
            return _self.viewModel[idx].columnCount
        }
        watefallLayout?.getInsetForSectionAtIndex = { [weak self] (idx) in
            guard let _self = self else { return UIEdgeInsets.zero }
            return _self.viewModel[idx].sectionInset
        }
        watefallLayout?.getSizeForItemAtIndexPath = { [weak self] (idx) in
            guard let _self = self else { return CGSize.zero }
            let source = _self.viewModel[idx.section].items[idx.row]
            let identifa = source.identifa as NSString
            guard let item = _self.calculateHeightCache.object(forKey: identifa)
                ?? source.newItem as? UICollectionReusableView else { return CGSize.zero }
            source.fillModel(for: item)
            _self.calculateHeightCache.setObject(item, forKey: identifa)
            return item.sizeThatFits(CGSize(width: _self.itemWidth(for: idx), height: 0))
        }
        watefallLayout?.getHeightForHeaderInSection = { [weak self] (idx) in
            guard let _self = self else { return 0 }
            guard let source = _self.viewModel[idx].header else { return 0 }
            let identifa = source.identifa as NSString
            guard let header = _self.calculateHeightCache.object(forKey: identifa)
                ?? source.newItem as? UICollectionReusableView else { return 0 }
            source.fillModel(for: header)
            _self.calculateHeightCache.setObject(header, forKey: identifa)
            return header.sizeThatFits(CGSize(width: _self.frame.width, height: 0)).height
        }
        watefallLayout?.getHeightForFooterInSection = { [weak self] (idx) in
            guard let _self = self else { return 0 }
            guard let source = _self.viewModel[idx].footer else { return 0 }
            let identifa = source.identifa as NSString
            guard let footer = _self.calculateHeightCache.object(forKey: identifa)
                ?? source.newItem as? UICollectionReusableView else { return 0 }
            source.fillModel(for: footer)
            _self.calculateHeightCache.setObject(footer, forKey: identifa)
            return footer.sizeThatFits(CGSize(width: _self.frame.width, height: 0)).height
        }
        watefallLayout?.getMinimumColumnSpacingForSectionAtIndex = { [weak self] (idx) in
            guard let _self = self else { return 0 }
            return CGFloat(_self.viewModel[idx].minimumColumnSpacing)
        }
        watefallLayout?.getMinimumInteritemSpacingForSectionAtIndex = { [weak self] (idx) in
            guard let _self = self else { return 0 }
            return CGFloat(_self.viewModel[idx].minimumInteritemSpacing)
        }
    }

    func itemWidth(for idx: NSIndexPath) -> CGFloat {
        let section = viewModel[idx.section]
        let width: CGFloat
        if section.columnCount > 1 {
            let contentWidth = frame.width
                - section.sectionInset.left
                - section.sectionInset.right
                - CGFloat(section.columnCount-1) * CGFloat(section.minimumColumnSpacing)
            width = contentWidth / CGFloat(section.columnCount)
        } else {
            width = frame.width
                - section.sectionInset.left
                - section.sectionInset.right
        }
        return width
    }

    func registerViewModels() {
        for section in viewModel {
            if let header = section.header {
                register(header.registClass,
                         forSupplementaryViewOfKind: CHTWaterfallLayout.ElementKindSection.header,
                         withReuseIdentifier: header.identifa)
            }
            if let footer = section.footer {
                register(footer.registClass,
                         forSupplementaryViewOfKind: CHTWaterfallLayout.ElementKindSection.footer,
                         withReuseIdentifier: footer.identifa)
            }
            for item in section.items {
                register(item.registClass, forCellWithReuseIdentifier: item.identifa)
            }
        }
    }
}
// MARK: - Getter
extension CHTWaterfallList {
    /// 内嵌瀑布流layout
    var watefallLayout: CHTWaterfallLayout? {
        return collectionViewLayout as? CHTWaterfallLayout
    }
}
extension CHTWaterfallList: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel[section].items.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        var returnCell: UICollectionViewCell

        if indexPath.section < viewModel.count,
            indexPath.row < viewModel[indexPath.section].items.count {
            let item = viewModel[indexPath.section].items[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.identifa,
                                                          for: indexPath)
            item.fillModel(for: cell)
            cell.sizeToFit()
            returnCell = cell
        } else {
            returnCell = UICollectionViewCell()
        }

        return returnCell
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        let returnView: UICollectionReusableView
        var item: CHTWaterfallListItemProtocol?

        if  indexPath.section < viewModel.count {
            if kind == CHTWaterfallLayout.ElementKindSection.header {
                item = viewModel[indexPath.section].header
            } else if kind == CHTWaterfallLayout.ElementKindSection.footer {
                item = viewModel[indexPath.section].footer
            }
        }

        if let item = item {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: item.identifa,
                                                                       for: indexPath)
            item.fillModel(for: view)
            returnView = view
        } else {
            returnView = UICollectionReusableView()
        }

        return returnView
    }
}
