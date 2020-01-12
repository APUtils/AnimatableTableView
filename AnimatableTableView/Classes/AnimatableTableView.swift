//
//  AnimatableTableView.swift
//  BaseClasses
//
//  Created by Anton Plebanovich on 1/7/20.
//  Copyright © 2020 Anton Plebanovich. All rights reserved.
//

import UIKit

public protocol AnimatableTableViewDataSource: UITableViewDataSource {
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath)
}

open class AnimatableTableView: UITableView {
    
//    open override var contentOffset: CGPoint {
//        didSet {
//            print("contentOffset: \(contentOffset.y)")
//        }
//    }
//    
//    open override var contentSize: CGSize {
//        didSet {
//            print("contentSize: \(contentSize.height)")
//        }
//    }
    
    // ******************************* MARK: - Initialization and Setup
    
    public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        setupFastTouches()
    }
    
    private func setupFastTouches() {
        delaysContentTouches = false
        
        for view in subviews {
            if let scrollView = view as? UIScrollView {
                scrollView.delaysContentTouches = false
                break
            }
        }
    }
    
    // ******************************* MARK: - Animations
    
    open func reloadRow(indexPath: IndexPath) {
        guard let dataSource = dataSource as? AnimatableTableViewDataSource else {
            print("AnimatableTableView: dataSource is missing or doesn't conform to `AnimatableTableViewDataSource`")
            return
        }
        
        guard let cell = cellForRow(at: indexPath), cell._isVisibleInWindow else { return super.reloadRows(at: [indexPath], with: .none) }
        
        // We reload cell manually and trigger table view cells height reload
        // so we can animate cell content changes.
        UIView.animate(withDuration: 0.3) {
            dataSource.configureCell(cell, forRowAt: indexPath)
            self.beginUpdates()
            self.endUpdates()
        }
    }
    
    open func deleteRow(indexPath: IndexPath) {
        guard let cell = cellForRow(at: indexPath), cell._isVisibleInWindow else { return super.deleteRows(at: [indexPath], with: .none) }
        super.deleteRows(at: [indexPath], with: .fade)
    }
    
    open func insertFirstRowAndScrollToIt() {
        
        // No need to worry if we can't yet scroll just use system method
        let firstRowIndexPath = IndexPath(row: 0, section: 0)
        
        guard _isScrollable else {
            insertRows(at: [firstRowIndexPath], with: .fade)
            return
        }
        
        // Several things happening here.
        // 1) .none - is a row animation. Table view still has expand animation with .insertRows call
        // 2) When table scrolled to the top, a new cell just expands from the top but
        // even when a new cell should appear under a transparent bar it first jump content offset to a new position and then
        // animates expand. It does it until first cell is far away from the screen so insertion is just broken for that case.
        // 3) On iOS 12.4 it behaves differenlty from iOS 13.3
        // 4) We might be scrolling
        
        // To cover all cases we completelly disable animations,
        // insert, fix content offset and then animate fade in manually.
        // After everything we scroll to top.
        
        // Stop active scrolling
        setContentOffset(contentOffset, animated: false)
        
        let canAnimate = contentOffset.y <= -_fullContentInsets.top
        var insertedCell: UITableViewCell?
        UIView.performWithoutAnimation {
            let originalContentOffset = contentOffset
            
            // As a fallback to restore offset
            let topCell = visibleCells.first
            let topCellOriginalOffset = topCell?.frame.minY
            var topCellIndexPath = topCell.flatMap { indexPath(for: $0) }
            topCellIndexPath?.row += 1
            
            // Insert cell
            // Sadly, there is no method to actually insert one row WITHOUT ANY FUCKING SCROLLS AND ANIMATIONS OMG WTF.
            reloadData()
            layoutIfNeeded()
            
            // Checking if it was added
            if let _insertedCell = cellForRow(at: firstRowIndexPath) {
                insertedCell = _insertedCell
                
                // Prepare fade in animation
                _insertedCell.alpha = 0
                
                // Fixing content offset
                let animationStartContentOffsetY = (originalContentOffset.y + _insertedCell.frame.size.height)._roundedToPixel
                let animationStartContentOffset = CGPoint(x: contentOffset.x, y: animationStartContentOffsetY)
                contentOffset = animationStartContentOffset
                layoutIfNeeded()
                    
                if animationStartContentOffsetY .!= contentOffset.y {
                    print("Offset was changed during layout")
                }
                
            } else if let topCellOriginalOffset = topCellOriginalOffset, let topCellIndexPath = topCellIndexPath, let topCell = cellForRow(at: topCellIndexPath) {
                if canAnimate {
                    print("Inserted cell is missing, thought, it was assuming possible to be animated.")
                }
                
                let contentOffsetFix = topCell.frame.minY - topCellOriginalOffset
                let animationStartContentOffsetY = (originalContentOffset.y + contentOffsetFix)._roundedToPixel
                let animationStartContentOffset = CGPoint(x: contentOffset.x, y: animationStartContentOffsetY)
                contentOffset = animationStartContentOffset
                layoutIfNeeded()
                
                if contentOffset.y .!= animationStartContentOffsetY {
                    print("Offset was changed during layout")
                }
                
            } else {
                print("Unable to restore top offset")
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            insertedCell?.alpha = 1
        }
        
        _scrollToTop(animated: true)
    }
    
    open func appendRowAndScrollToIt() {
        // Table view adds cell without animations at the bottom if it outside of visible bounds
        // So need to animate it manually.
        
        // Stop active scrolling
        setContentOffset(contentOffset, animated: false)
        
        // TODO: Animate manually always
        let sectionsCount = dataSource?.numberOfSections?(in: self) ?? 0
        guard let rowsCount = dataSource?.tableView(self, numberOfRowsInSection: sectionsCount) else { return }
        let lastRowIndexPath = IndexPath(row: rowsCount - 1, section: sectionsCount)
        
        let canAnimate = _visibleFrame.maxY .>= _contentFrame.maxY
        if canAnimate {
            if _visibleFrame.maxY .> _contentFrame.maxY {
                // Cell will be loaded and animated
                insertRows(at: [lastRowIndexPath], with: .fade)
                
            } else {
                UIView.performWithoutAnimation {
                    // Notify table view about new cell and prepare it for a fade in animation.
                    insertRows(at: [lastRowIndexPath], with: .none)
                    if let cell = cellForRow(at: lastRowIndexPath) {
                        // In some cases it might be loaded.
                        cell.alpha = 0
                        
                    } else {
                        // In some cases it might not be loaded.
                        // Make added cell visible so it'll be loaded.
                        // Sadly, we need to do it twice.
                        contentOffset.y += 1
                        layoutIfNeeded()
                        contentOffset.y += 1
                        cellForRow(at: lastRowIndexPath)?.alpha = 0
                    }
                }
                
                // Fade in
                UIView.animate(withDuration: 0.3) {
                    self.cellForRow(at: lastRowIndexPath)?.alpha = 1
                }
            }
            
        } else {
            insertRows(at: [lastRowIndexPath], with: .none)
        }
        
        _scrollToBottom(animated: true)
    }
    
    // ******************************* MARK: - UIScrollView Overrides
    
    override open func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIButton {
            return true
        }
        
        return super.touchesShouldCancel(in: view)
    }
}

// ******************************* MARK: - CustomStringConvertible

extension AnimatableTableView {
    open override var description: String {
        var descriptionComponents: [String] = []
        
        // Class
        let typeDescription = NSStringFromClass(type(of: self))
        let pointerDescription = Unmanaged<AnyObject>.passUnretained(self).toOpaque().debugDescription
        let classDescription = "\(typeDescription): \(pointerDescription)"
        descriptionComponents.append(classDescription)
        
        // Frame
        let frameDescription = "(\(frame.minX._asString) \(frame.minY._asString); \(frame.maxX._asString) \(frame.maxY._asString))"
        descriptionComponents.append("frame = \(frameDescription)")
        
        // Insets
        let fullContentInsets = _fullContentInsets
        if fullContentInsets != .zero {
            let insetsDescription = "{\(fullContentInsets.top._asString), \(fullContentInsets.left._asString), \(fullContentInsets.bottom._asString), \(fullContentInsets.right._asString)}"
            descriptionComponents.append("fullContentInsets = \(insetsDescription)")
        }
        
        // Content Size
        let contentSizeDescription = "(\(contentSize.width._asString), \(contentSize.height._asString))"
        descriptionComponents.append("contentSize = \(contentSizeDescription)")
        
        // Offset
        if contentOffset != .zero {
            // Add info
            let contentOffsetDescription = "{\(contentOffset.x._asString), \(contentOffset.y._asString)}"
            descriptionComponents.append("contentOffset = \(contentOffsetDescription)")
        }
        
        return "<\(descriptionComponents.joined(separator: "; "))>"
    }
}

private extension FloatingPoint {
    /// Checks if `self` is whole number.
    var _isWhole: Bool {
        return truncatingRemainder(dividingBy: 1) == 0
    }
}

private extension CGFloat {
    var _asString: String {
        if _isWhole {
            return "\(Int(self))"
        } else {
            return String(format: "%.1f", self)
        }
    }
}

