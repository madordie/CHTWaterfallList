//
//  CHTWaterfallLayout.swift
//  CHTWaterfallLayout
//
//  Created by 孙继刚 on 2017/4/8.
//  Copyright © 2017年 madordie. All rights reserved.
//

import UIKit

extension CHTWaterfallLayout {

    /// Enumerated structure to define direction in which items can be rendered.
    ///
    /// - shortestFirst: shortest column fills first
    /// - leftToRight: left to right
    /// - rightToLeft: right to left
    enum ItemRenderDirection {
        case shortestFirst, leftToRight, rightToLeft
    }

    /// Constants that specify the types of supplementary views that can be presented using a waterfall layout.
    struct ElementKindSection {
        /// A supplementary view that identifies the header for a given section.
        static let header = "CHTWaterfallLayout.ElementKindSection.header"
        /// A supplementary view that identifies the footer for a given section.
        static let footer = "CHTWaterfallLayout.ElementKindSection.footer"
    }

    /// see UITableViewStyle
    ///
    /// - plain: no adsorb
    /// - group: header adsorb
    enum Style {
        case plain, group
    }

    // MARK : fileprivate

    fileprivate struct Default {
        /// How many items to be union into a single rectangle
        static let unionSize = 20
    }

    fileprivate func PX(_ value: CGFloat) -> CGFloat {
        let scale = UIScreen.main.scale
        return floor(value * scale) / scale
    }
}

class CHTWaterfallLayout: UICollectionViewLayout {

    /// style defult plain.
    public var style = Style.plain {
        didSet { invalidateLayout() }
    }

    /// How many columns for this layout.
    public var getColumnCountForSection: ((_ section: Int) -> Int)?
    public var columnCount: Int = 2 {
        didSet { invalidateLayout() }
    }

    /// The minimum spacing to use between successive columns.
    public var getMinimumColumnSpacingForSectionAtIndex: ((_ index: Int) -> CGFloat)?
    public var minimumColumnSpacing: CGFloat = 10 {
        didSet { invalidateLayout() }
    }

    /// The minimum spacing to use between items in the same column.
    public var getMinimumInteritemSpacingForSectionAtIndex: ((_ index: Int) -> CGFloat)?
    public var minimumInteritemSpacing: CGFloat = 10 {
        didSet { invalidateLayout() }
    }

    /// Height for section header
    public var getHeightForHeaderInSection: ((_ section: Int) -> CGFloat)?
    public var headerHeight: CGFloat = 0 {
        didSet { invalidateLayout() }
    }

    /// Height for section footer
    public var getHeightForFooterInSection: ((_ section: Int) -> CGFloat)?
    public var footerHeight: CGFloat = 0 {
        didSet { invalidateLayout() }
    }

    /// The margins that are used to lay out the header for each section.
    public var getInsetForHeaderInSection: ((_ section: Int) -> UIEdgeInsets)?
    public var headerInset: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }

    /// The margins that are used to lay out the footer for each section.
    public var getInsetForFooterInSection: ((_ section: Int) -> UIEdgeInsets)?
    public var footerInset: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }

    /// The margins that are used to lay out content in each section.
    public var getInsetForSectionAtIndex: ((_ section: Int) -> UIEdgeInsets)?
    public var sectionInset: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }

    /// The direction in which items will be rendered in subsequent rows.
    public var itemRenderDirection: ItemRenderDirection = .shortestFirst {
        didSet { invalidateLayout() }
    }

    /// The minimum height of the collection view's content.
    public var minimumContentHeight: CGFloat = 0

    /// Asks the delegate for the size of the specified item’s cell.
    public var getSizeForItemAtIndexPath: ((_ indexPath: NSIndexPath) -> CGSize)?

    // MARK : fileprivate

    fileprivate var delegate: NSObject?
    /// Array to store height for each column
    fileprivate var columnHeights: [[CGFloat]] = []
    /// Array of arrays. Each array stores item attributes for each section
    fileprivate var sectionItemAttributes: [[UICollectionViewLayoutAttributes]] = []
    /// Array to store attributes for all items includes headers, cells, and footers
    fileprivate var allItemAttributes: [UICollectionViewLayoutAttributes] = []
    /// Dictionary to store section headers' attribute
    fileprivate var headersAttribute: [Int: UICollectionViewLayoutAttributes] = [:]
    /// Dictionary to store section footers' attribute
    fileprivate var footersAttribute: [Int: UICollectionViewLayoutAttributes] = [:]
    /// Array to store union rectangles
    fileprivate var unionRects: [CGRect] = []
}

fileprivate extension CHTWaterfallLayout {
    func columnCountForSection(_ section: Int) -> Int {
        guard let count = getColumnCountForSection?(section) else {
            return columnCount
        }
        return count
    }
    func itemWidthInSectionAtIndex(_ section: Int) -> CGFloat {
        guard let collectionView = self.collectionView else { return 0 }

        let sectionInset = getInsetForSectionAtIndex?(section) ?? self.sectionInset
        let width = collectionView.bounds.width - sectionInset.left - sectionInset.right
        let columnCount = columnCountForSection(section)
        let columnSpacing = getMinimumColumnSpacingForSectionAtIndex?(section) ?? self.minimumColumnSpacing

        return PX((width - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount))
    }
}

extension CHTWaterfallLayout {
    override func prepare() {
        super.prepare()

        headersAttribute.removeAll()
        footersAttribute.removeAll()
        unionRects.removeAll()
        columnHeights.removeAll()
        allItemAttributes.removeAll()
        sectionItemAttributes.removeAll()

        guard let collectionView = self.collectionView else { return }

        let numberOfSection = collectionView.numberOfSections
        guard numberOfSection != 0 else { return }

        // Initialize variables
        for section in 0..<numberOfSection {
            let columnCount = columnCountForSection(section)
            var sectionColumnHeights = [CGFloat]()
            for _ in 0..<columnCount {
                sectionColumnHeights.append(0)
            }
            columnHeights.append(sectionColumnHeights)
        }

        // Create attributes
        var top: CGFloat = 0
        for section in 0..<numberOfSection {
            /*
             * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
             */
            let minimumInteritemSpacing = getMinimumInteritemSpacingForSectionAtIndex?(section) ?? self.minimumInteritemSpacing
            let columnSpacing = getMinimumColumnSpacingForSectionAtIndex?(section) ?? self.minimumColumnSpacing
            let sectionInset =  getInsetForSectionAtIndex?(section) ?? self.sectionInset
            let width = collectionView.bounds.width - sectionInset.left - sectionInset.right
            let columnCount = columnCountForSection(section)
            let itemWidth = PX((width - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount))
            /*
             * 2. Section header
             */
            let headerHeight = getHeightForHeaderInSection?(section) ?? self.headerHeight
            let headerInset = getInsetForHeaderInSection?(section) ?? self.headerInset

            top += headerInset.top

            if headerHeight > 0 {
                let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: ElementKindSection.header,
                                                                  with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: headerInset.left,
                                          y: top,
                                          width: collectionView.bounds.width - (headerInset.left + headerInset.right),
                                          height: headerHeight)
                headersAttribute[section] = attributes
                allItemAttributes.append(attributes)

                top = attributes.frame.maxY + headerInset.bottom
            }

            top += sectionInset.top
            for idx in 0..<columnCount {
                columnHeights[section][idx] = top
            }

            /*
             * 3. Section items
             */
            let itemCount = collectionView.numberOfItems(inSection: section)
            let itemAttributes = [UICollectionViewLayoutAttributes]()
            for idx in 0..<itemCount {
                let indexPath = NSIndexPath(item: idx, section: section)
                let columnIndex = nextColumnIndex(forItem: idx, inSection: section)
                let xOffset = sectionInset.left + (itemWidth + columnSpacing) * CGFloat(columnIndex)
                let yOffset = columnHeights[section][columnIndex]
                let itemSize = getSizeForItemAtIndexPath?(indexPath) ?? CGSize.zero
                var itemHeight: CGFloat = 0
                if itemSize.height > 0 && itemSize.width > 0 {
                    itemHeight = PX(itemSize.height * itemWidth / itemSize.width)
                }

                let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: indexPath.row, section: indexPath.section))
                attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemWidth, height: itemHeight)
                allItemAttributes.append(attributes)
                columnHeights[section][columnIndex] = attributes.frame.maxY + minimumInteritemSpacing
            }

            sectionItemAttributes.append(itemAttributes)

            /*
             * 4. Section footer
             */
            let columnIndex = longestColumnIndex(inSection: section)
            top = columnHeights[section].count > 0
                    ? columnHeights[section][columnIndex] - minimumInteritemSpacing + sectionInset.bottom
                    : 0
            let footerHeight = getHeightForFooterInSection?(section) ?? self.footerHeight
            let footerInset = getInsetForFooterInSection?(section) ?? self.footerInset

            top += footerInset.top

            if footerHeight > 0 {
                let attributes =  UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: ElementKindSection.footer,
                                                                   with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: footerInset.left,
                                          y: top,
                                          width: collectionView.bounds.width - (footerInset.left + footerInset.right),
                                          height: footerHeight)
                footersAttribute[section] = attributes
                allItemAttributes.append(attributes)

                top = attributes.frame.maxY + footerInset.bottom
            }

            for idx in 0..<columnCount {
                columnHeights[section][idx] = top
            }
        } // end of for (NSInteger section = 0; section < numberOfSections; ++section)

        // Build union rects
        var idx = 0
        let itemCounts = allItemAttributes.count
        while idx < itemCounts {
            var unionRect = allItemAttributes[idx].frame
            let rectEndIndex = min(idx + Default.unionSize, itemCounts)

            for i in (idx + 1)..<rectEndIndex {
                unionRect = CGRect.union(unionRect)(allItemAttributes[i].frame)
            }

            idx = rectEndIndex

            unionRects.append(unionRect)
        }
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = self.collectionView else { return CGSize.zero }

        let numberOfSections = collectionView.numberOfSections
        guard numberOfSections > 0 else { return CGSize.zero }

        var contentSize = collectionView.bounds.size
        contentSize.height = columnHeights.last?.first ?? 0

        contentSize.height = max(contentSize.height, minimumContentHeight)

        return contentSize
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < sectionItemAttributes.count else { return nil }
        guard indexPath.item < sectionItemAttributes[indexPath.section].count else { return nil }

        return sectionItemAttributes[indexPath.section][indexPath.item]
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        var attribute: UICollectionViewLayoutAttributes?
        if elementKind == ElementKindSection.header {
            attribute = headersAttribute[indexPath.section]
        } else if elementKind == ElementKindSection.footer {
            attribute = footersAttribute[indexPath.section]
        }
        return attribute
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var begin = 0
        var end = unionRects.count

        for i in 0..<unionRects.count {
            if CGRect.intersects(rect)(unionRects[i]) {
                begin = i * Default.unionSize
                break
            }
        }
        var i = unionRects.count - 1
        while i >= 0 {
            if CGRect.intersects(rect)(unionRects[i]) {
                end = min((i + 1) * Default.unionSize, allItemAttributes.count)
                break
            }
            i -= 1
        }
        var suppls = [UICollectionViewLayoutAttributes]()
        var decos = [UICollectionViewLayoutAttributes]()
        var cells = [UICollectionViewLayoutAttributes]()
        for i in begin..<end {
            let attr = allItemAttributes[i]
            if CGRect.intersects(rect)(attr.frame) {
                switch attr.representedElementCategory {
                case .supplementaryView:
                    suppls.append(attr)
                case .decorationView:
                    decos.append(attr)
                case .cell:
                    cells.append(attr)
                }
            }
        }
        return cells + suppls + decos
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = self.collectionView else { return false }

        let oldBounds = collectionView.bounds
        if newBounds.width != oldBounds.width {
            return true
        }
        return false
    }
}

fileprivate extension CHTWaterfallLayout {
    func nextColumnIndex(forItem item: Int, inSection section: Int) -> Int {
        var index = 0

        let columnCount = columnCountForSection(section)
        switch itemRenderDirection {
        case .shortestFirst:
            index = shortestColumnIndex(inSection: section)
        case .leftToRight:
            index = item % columnCount
        case .rightToLeft:
            index = (columnCount - 1) - (item % columnCount)
        }
        return index
    }
    func shortestColumnIndex(inSection section: Int) -> Int {
        var index = 0
        var shortesHeight = CGFloat.greatestFiniteMagnitude

        var idx = 0
        for height in columnHeights[section] {
            if height < shortesHeight {
                shortesHeight = height
                index = idx
            }
            idx += 1
        }
        return index
    }
    func longestColumnIndex(inSection section: Int) -> Int {
        var index = 0
        var longestHeight:CGFloat = 0

        var idx = 0
        for height in columnHeights[section] {
            if height > longestHeight {
                longestHeight = height
                index = idx
            }
            idx += 1
        }
        return index
    }
}
