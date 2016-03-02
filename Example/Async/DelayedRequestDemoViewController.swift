//
//  DelayedRequestDemoViewController.swift
//  AsyncDemo
//
//  Created by Zhixuan Lai on 2/24/16.
//  Copyright © 2016 Zhixuan Lai. All rights reserved.
//

import UIKit
import ReactiveUI
import SwiftAsync

class DelayedRequestDemoViewController: UITableViewController {

    var requests = [DelayedRequest]()
    let numberOfRequests = 10

    override func viewDidLoad() {
        super.viewDidLoad()

        let rightBarButtonItemTitle = "Reload"

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonItemTitle, style: .Plain) {[unowned self] item in
            self.reload()
        }

        reload()
    }

    func reload() {

    }

    func updateRequest(index: Int, state: DelayedRequest.State) {
        async(.Main) {[unowned self] in
            self.requests[index].state = state
            self.tableView.reloadData()
        }() {}
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requests.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = String(format: "s%li-r%li", indexPath.section, indexPath.row)
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
        }

        let request = requests[indexPath.row]
        cell.textLabel?.text = "Delay: \(request.delay)   State: \(request.state.description)"
        switch request.state {
        case .Pending:
            cell.accessoryView = nil
        case .Running:
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            spinner.startAnimating()
            cell.accessoryView = spinner
        case .Finished:
            cell.accessoryView = nil
            cell.accessoryType = .Checkmark
        }

        return cell
    }

}
