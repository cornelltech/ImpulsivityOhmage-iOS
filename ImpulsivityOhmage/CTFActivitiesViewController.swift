//
//  CTFActivitiesViewController.swift
//  ImpulsivityOhmage
//
//  Created by James Kizer on 1/29/17.
//  Copyright © 2017 Foundry @ Cornell Tech. All rights reserved.
//

import UIKit
import Gloss
import ResearchKit
import ResearchSuiteTaskBuilder

class CTFActivitiesViewController: UITableViewController, ORKTaskViewControllerDelegate {

    var activityFileName: String?
    
    var schedule: CTFSchedule?
    var visibleItems: [CTFScheduleItem]?
    
    var taskFinishedHandler: ((ORKTaskViewController, ORKTaskViewControllerFinishReason, Error?) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        // Do any additional setup after loading the view.
        
        if let filename = self.activityFileName,
            let json = CTFTaskBuilderManager.getJson(forFilename: filename) as? JSON,
            let schedule = CTFSchedule(json: json) {
            
            debugPrint(schedule)
            
            self.schedule = schedule
            
        }
        
        
    }
    
    func shouldShowScheduleItem(item: CTFScheduleItem) -> Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let schedule = self.schedule else {
            return
        }
        
        self.visibleItems = schedule.items.filter(self.shouldShowScheduleItem)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            guard let visibleItems = self.visibleItems else {
                return 0
            }
            
            return visibleItems.count
        }
        else {
            return 0
        }
    }
    
    private func scheduleItem(forIndexPath indexPath: IndexPath) -> CTFScheduleItem? {
        guard indexPath.section == 0,
            let visibleItems = self.visibleItems,
            visibleItems.count > indexPath.row else {
                return nil
        }
        
        return visibleItems[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let identifier = "activity_cell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        if let item = self.scheduleItem(forIndexPath: indexPath) {
            cell.textLabel?.text = item.title
        }
        
        return cell
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        taskFinishedHandler?(taskViewController, reason, error)
        
        
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let item = self.scheduleItem(forIndexPath: indexPath),
            let steps = CTFTaskBuilderManager.sharedBuilder.steps(forElement: item.activity as JsonElement) else {
                return
        }
        
        let task = ORKOrderedTask(identifier: item.identifier, steps: steps)
        
        let taskViewController = ORKTaskViewController(task: task, taskRun: nil)
        taskViewController.delegate = self
        
        self.taskFinishedHandler = { [weak self] (taskViewController, reason, error) in
            
            if reason == ORKTaskViewControllerFinishReason.completed {
                
                let taskResult: ORKTaskResult = taskViewController.result
                
                CTFResultFrontEndManager.sharedInstance.processResult(taskResult: taskResult, resultTransforms: item.resultTransforms)
                
                
            }
            
            self?.dismiss(animated: true, completion: { 
                
                
            })
            
        }
        
        
        present(taskViewController, animated: true, completion: nil)
        
        
    }
    
    
    

}
