# FlowSure Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         FlowSure System                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────┐
│   User/dApp │
└──────┬──────┘
       │
       │ 1. Execute Insured Action
       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      InsuredAction.cdc                           │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  insuredAction(user, targetAction, params, retryLimit) │    │
│  └────────────────────────────────────────────────────────┘    │
│                           │                                      │
│                           ▼                                      │
│                    Execute Action                                │
│                           │                                      │
│              ┌────────────┴────────────┐                        │
│              ▼                         ▼                         │
│         ✅ Success                 ❌ Failure                    │
│              │                         │                         │
│              │                         ▼                         │
│              │              ┌──────────────────┐                │
│              │              │ Check Retry Count│                │
│              │              └────────┬─────────┘                │
│              │                       │                           │
│              │          ┌────────────┴────────────┐             │
│              │          ▼                         ▼              │
│              │    Retries < Limit          Retries >= Limit     │
│              │          │                         │              │
└──────────────┼──────────┼─────────────────────────┼─────────────┘
               │          │                         │
               │          ▼                         ▼
               │  ┌───────────────┐      ┌──────────────────┐
               │  │ Scheduler.cdc │      │InsuranceVault.cdc│
               │  │               │      │                  │
               │  │ scheduleRetry │      │   payOut(user)   │
               │  └───────┬───────┘      └────────┬─────────┘
               │          │                       │
               │          │ Wait delay            │
               │          │                       │
               │          ▼                       │
               │  executeScheduledRetry           │
               │          │                       │
               │          └───────┐               │
               │                  │               │
               ▼                  ▼               ▼
         ┌─────────────────────────────────────────┐
         │           Events.cdc                     │
         │  • TransactionStatusEvent                │
         │  • ActionSuccessEvent                    │
         │  • ActionFailureEvent                    │
         │  • RetryScheduledEvent                   │
         │  • CompensationEvent                     │
         │  • VaultDepositEvent                     │
         │  • VaultPayoutEvent                      │
         └─────────────────────────────────────────┘
                          │
                          ▼
                  ┌──────────────┐
                  │   Frontend   │
                  │  Monitoring  │
                  └──────────────┘
```

## Contract Interactions

### 1. InsuredAction → Scheduler

```cadence
// When action fails and retries remain
let schedulerRef = Scheduler.borrowSchedulerManager()
schedulerRef.scheduleRetry(
    actionId: actionId,
    user: user,
    targetAction: targetAction,
    params: params,
    retryLimit: retryLimit,
    delay: defaultRetryDelay
)
```

### 2. InsuredAction → InsuranceVault

```cadence
// When all retries exhausted
InsuranceVault.payOut(
    user: user,
    amount: defaultCompensationAmount
)
```

### 3. InsuredAction → Events

```cadence
// Throughout execution
emit Events.ActionSuccessEvent(...)
emit Events.ActionFailureEvent(...)
emit Events.TransactionStatusEvent(...)
emit Events.CompensationEvent(...)
```

### 4. Scheduler → Events

```cadence
// When scheduling retry
emit Events.RetryScheduledEvent(...)
```

### 5. InsuranceVault → Events

```cadence
// On deposits and payouts
emit Events.VaultDepositEvent(...)
emit Events.VaultPayoutEvent(...)
```

## Data Flow

### Successful Action Flow

```
User → insuredAction()
         ↓
    Execute Action
         ↓
    ✅ Success
         ↓
    Update Record (status: SUCCESS)
         ↓
    Emit ActionSuccessEvent
         ↓
    Emit TransactionStatusEvent
         ↓
    Return to User
```

### Failed Action Flow (with retries)

```
User → insuredAction()
         ↓
    Execute Action
         ↓
    ❌ Failure
         ↓
    Emit ActionFailureEvent
         ↓
    Check Retry Count
         ↓
    Retries < Limit
         ↓
    Schedule Retry (Scheduler)
         ↓
    Emit RetryScheduledEvent
         ↓
    Update Record (status: RETRY_SCHEDULED)
         ↓
    [Wait for delay]
         ↓
    executeScheduledRetry()
         ↓
    Execute Action Again
         ↓
    [Repeat until success or limit reached]
```

### Compensation Flow

```
Final Retry Failed
         ↓
    Check Retry Count
         ↓
    Retries >= Limit
         ↓
    Call InsuranceVault.payOut()
         ↓
    Transfer FLOW to User
         ↓
    Update Vault Stats
         ↓
    Emit VaultPayoutEvent
         ↓
    Emit CompensationEvent
         ↓
    Update Record (status: COMPENSATED)
         ↓
    Emit TransactionStatusEvent
```

## Resource Management

### Storage Paths

```
InsuranceVault:
  - /storage/FlowSureVault (Vault resource)
  - /public/FlowSureVault (Public capability)
  - /storage/FlowSureAdmin (Admin resource)

Scheduler:
  - /storage/FlowSureScheduler (SchedulerManager resource)

InsuredAction:
  - /storage/FlowSureActionManager (ActionManager resource)
```

### Resource Ownership

```
Contract Account
    ├── InsuranceVault.Vault (owned by contract)
    ├── InsuranceVault.Administrator (owned by contract)
    ├── Scheduler.SchedulerManager (owned by contract)
    └── InsuredAction.ActionManager (owned by contract)
```

## State Management

### InsuredAction State

```
ActionRecord {
    actionId: String
    user: Address
    targetAction: String
    status: String  // INITIATED, SUCCESS, RETRY_SCHEDULED, COMPENSATED
    retries: UInt8
    createdAt: UFix64
    lastAttemptAt: UFix64
}
```

### Scheduler State

```
ScheduledAction {
    actionId: String
    user: Address
    targetAction: String
    params: {String: AnyStruct}
    retryCount: UInt8
    retryLimit: UInt8
    scheduledFor: UFix64
    createdAt: UFix64
}
```

### InsuranceVault State

```
VaultData {
    totalPoolBalance: UFix64
    totalDeposits: UFix64
    totalPayouts: UFix64
    activeUsers: UInt64
}
```

## Event Flow Timeline

```
Time    Event                           Emitter
─────────────────────────────────────────────────────────────
T0      VaultDepositEvent              InsuranceVault
        (User funds vault)

T1      TransactionStatusEvent         InsuredAction
        (status: INITIATED)

T2      ActionFailureEvent             InsuredAction
        (First attempt fails)

T3      RetryScheduledEvent            Scheduler
        (Retry scheduled for T4)

T4      ActionFailureEvent             InsuredAction
        (Retry attempt fails)

T5      RetryScheduledEvent            Scheduler
        (Retry scheduled for T6)

T6      ActionFailureEvent             InsuredAction
        (Final retry fails)

T7      VaultPayoutEvent               InsuranceVault
        (Compensation paid)

T8      CompensationEvent              InsuredAction
        (User compensated)

T9      TransactionStatusEvent         InsuredAction
        (status: FAILED_COMPENSATED)
```

## Security Model

### Access Control

```
Public Functions:
  - insuredAction() (anyone can execute)
  - deposit() (anyone can deposit)
  - getVaultStats() (read-only)
  - getActionRecord() (read-only)

Account Access:
  - payOut() (only InsuredAction contract)
  - borrowSchedulerManager() (only InsuredAction contract)

Admin Only:
  - emergencyWithdraw() (requires Administrator resource)
```

### Safety Checks

```
Pre-conditions:
  ✓ Vault has sufficient balance before payout
  ✓ Retry count doesn't exceed limit
  ✓ Action is ready for retry (time check)
  ✓ Valid action type

Post-conditions:
  ✓ Vault balance updated correctly
  ✓ Action records maintained
  ✓ Events emitted for all state changes
```

## Integration Points

### Frontend Integration

```javascript
// Listen to events
flow.events.subscribe('A.CONTRACT.Events.TransactionStatusEvent', (event) => {
    // Update UI with action status
});

// Execute insured action
await flow.send([
    transaction(EXECUTE_INSURED_ACTION),
    args([arg("token_swap", t.String), arg(false, t.Bool), arg(3, t.UInt8)]),
    payer(authz),
    proposer(authz),
    authorizations([authz])
]);
```

### Backend Integration

```javascript
// Monitor scheduled retries
const scheduledActions = await flow.query({
    cadence: GET_SCHEDULED_ACTIONS
});

// Execute retry when ready
if (isReadyForRetry(action)) {
    await flow.send([
        transaction(EXECUTE_SCHEDULED_RETRY),
        args([arg(actionId, t.String)]),
        payer(authz),
        proposer(authz),
        authorizations([authz])
    ]);
}
```

## Scalability Considerations

### Current Design
- In-memory storage for actions and retries
- Suitable for moderate transaction volume
- Event-based monitoring

### Future Enhancements
- Action archival for old records
- Batch retry execution
- Dynamic compensation calculation
- Multi-token support
- Governance for parameter adjustment

## Performance Characteristics

### Gas Costs (Approximate)
- Deploy contracts: ~0.001 FLOW per contract
- Execute action: ~0.0001 FLOW
- Schedule retry: ~0.00005 FLOW
- Deposit to vault: ~0.0001 FLOW
- Query scripts: Free (read-only)

### Timing
- Action execution: Immediate
- Retry delay: Configurable (default 60s)
- Event emission: Immediate
- Compensation: Immediate after final retry

## Error Handling

```
Error Scenarios:
1. Insufficient vault balance
   → Transaction reverts, no payout

2. Action not found
   → Returns nil, no state change

3. Retry not ready
   → Returns error result, no execution

4. Invalid action type
   → Returns failure result, schedules retry

5. Vault reference unavailable
   → Panic with descriptive message
```

## Monitoring & Observability

### Key Metrics
- Action success rate
- Average retries per action
- Vault balance trend
- Compensation frequency
- Retry delay effectiveness

### Event Monitoring
- Real-time status updates
- Historical action analysis
- Vault activity tracking
- Retry pattern analysis

---

This architecture provides a robust, scalable foundation for insured on-chain actions with automatic retry and compensation mechanisms.
