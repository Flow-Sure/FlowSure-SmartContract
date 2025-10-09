import Scheduler from "../contracts/Scheduler.cdc"

access(all) fun main(): [Scheduler.ScheduledAction] {
    let schedulerRef = Scheduler.borrowSchedulerManager()
    return schedulerRef.getAllScheduledActions()
}
