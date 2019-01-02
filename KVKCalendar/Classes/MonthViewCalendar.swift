//
//  MonthViewCalendar.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class MonthViewCalendar: UIView, MonthCellDelegate {
    fileprivate var data: MonthData
    fileprivate let style: Style
    
    weak var delegate: CalendarSelectDateDelegate?
    
    fileprivate lazy var headerView: WeekHeaderView = {
        var newWidth = UIScreen.main.bounds.width
        if let window = UIApplication.shared.delegate?.window as? UIWindow {
            newWidth = window.frame.width
        }
        let view = WeekHeaderView(frame: CGRect(x: 0, y: 0, width: newWidth, height: 50))
        view.backgroundColor = style.weekStyle.colorBackgroundWeekdayDate
        return view
    }()
    
    fileprivate lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = style.weekStyle.scrollDirection
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.isPagingEnabled = true
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    init(data: MonthData, frame: CGRect, style: Style) {
        self.data = data
        self.style = style
        super.init(frame: frame)
        addSubview(headerView)
        
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView.frame = collectionFrame
        addSubview(collectionView)
        
        collectionView.register(MonthCollectionViewCell.self,
                                forCellWithReuseIdentifier: MonthCollectionViewCell.cellIdentifier)
        scrollToDate(date: data.moveDate)
    }
    
    func setDate(date: Date) {
        data.moveDate = date
        scrollToDate(date: date)
        collectionView.reloadData()
    }
    
    func reloadData(events: [Event]) {
        data.reloadEventsInDays(events: events)
        collectionView.reloadData()
    }
    
    fileprivate func scrollToDate(date: Date) {
        delegate?.didSelectCalendarDate(date, type: .month)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let idx = self.data.days.index(where: { $0.date?.month == date.month && $0.date?.year == date.year }) {
                self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                 at: .top,
                                                 animated: true)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didSelectEvent(_ event: Event, bounds: CGRect?) {
        delegate?.didSelectCalendarEvent(event)
    }
    
    func didSelectMore(_ date: Date, bounds: CGRect?) {
        delegate?.didSelectCalendarDate(date, type: .day)
    }
}

extension MonthViewCalendar: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MonthCollectionViewCell.cellIdentifier,
                                                      for: indexPath) as? MonthCollectionViewCell ?? MonthCollectionViewCell()
        let day = data.days[indexPath.row]
        cell.style = style.monthStyle
        cell.day = day
        cell.selectDate = data.moveDate
        cell.events = day.events
        cell.delegate = self
        return cell
    }
}

extension MonthViewCalendar: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cells = collectionView.visibleCells as? [MonthCollectionViewCell] ?? [MonthCollectionViewCell()]
        let cellDays = cells.filter({ $0.day.type != .empty })
        guard let newMoveDate = cellDays.filter({ $0.day.date?.day == data.moveDate.day }).first?.day.date else { return }
        data.moveDate = newMoveDate
        delegate?.didSelectCalendarDate(newMoveDate, type: .month)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.3,
                       initialSpringVelocity: 0.8,
                       options: .curveLinear,
                       animations: { cell?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) },
                       completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.1) {
            cell?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widht: CGFloat
        let height: CGFloat
        
        switch style.weekStyle.scrollDirection {
        case .horizontal:
            widht = collectionView.frame.width / 7
            height = collectionView.frame.height / 6
        case .vertical:
            widht = collectionView.frame.width / 7
            height = collectionView.frame.height / 6
        }
        
        return CGSize(width: widht, height: height)
    }
}