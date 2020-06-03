//
//  CalendarTableViewController.swift
//  TUM Campus App
//
//  Created by Tim Gymnich on 2/19/19.
//  Copyright © 2019 TUM. All rights reserved.
//

import UIKit
import CoreData
import XMLParsing
import Alamofire

final class CalendarTableViewController: UITableViewController, EntityTableViewControllerProtocol {
    typealias ImporterType = Importer<CalendarEvent,APIResponse<CalendarAPIResponse,TUMOnlineAPIError>,XMLDecoder>
    
    private let endpoint: URLRequestConvertible = TUMOnlineAPI.calendar
    private let sortDescriptor = NSSortDescriptor(keyPath: \CalendarEvent.startDate, ascending: true)
    lazy var importer = ImporterType(endpoint: endpoint, sortDescriptor: sortDescriptor, dateDecodingStrategy: .formatted(.yyyyMMddhhmmss))

    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        setupTableView()
        importer.fetchedResultsController.delegate = self
        title = "Calendar".localized
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        fetch(animated: animated)
    }

    @objc private func fetch(animated: Bool = true) {
        if animated {
            tableView.refreshControl?.beginRefreshing()
        }
        importer.performFetch(success: { [weak self] in
            self?.tableView.refreshControl?.endRefreshing()
            try? self?.importer.fetchedResultsController.performFetch()
            self?.tableView.reloadData()
        }, error: { [weak self] error in
            self?.tableView.refreshControl?.endRefreshing()
            guard error is TUMOnlineAPIError else { return }
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: CalendarEvent.fetchRequest())
            _ = try? self?.importer.context.execute(deleteRequest)
            try? self?.importer.fetchedResultsController.performFetch()
            self?.tableView.reloadData()
            self?.setBackgroundLabel(with: error.localizedDescription)
        })
    }

    private func setupTableView() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetch), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = UIView()
    }

   // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let numberOfSections = importer.fetchedResultsController.sections?.count

        switch numberOfSections {
        case let .some(count) where count > 0:
            tableView.backgroundView = nil
        case let .some(count) where count == 0:
            setBackgroundLabel(with: "No Calendar Events".localized)
        default:
            break
        }

        return numberOfSections ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return importer.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CalendarEventCell.reuseIdentifier, for: indexPath) as! CalendarEventCell
        let event = importer.fetchedResultsController.object(at: indexPath)

        cell.configure(event: event)

        return cell
    }
    
}