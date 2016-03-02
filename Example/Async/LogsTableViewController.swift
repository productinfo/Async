//
//  DefaultDemoViewController.swift
//  AsyncDemo
//
//  Created by Zhixuan Lai on 2/25/16.
//  Copyright © 2016 Zhixuan Lai. All rights reserved.
//

import UIKit
import SwiftAsync

class LogsTableViewController: UITableViewController {

    var logs = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    func log(message: String) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let message = "\(dateFormatter.stringFromDate(NSDate())) \(message)"

        logs.append(message)
        print(message)
        async(.Main) {
            self.tableView.reloadData()
        }() {}
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = String(format: "s%li-r%li", indexPath.section, indexPath.row)
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
        }

        cell.textLabel?.text = logs[indexPath.row]
        return cell
    }

}
