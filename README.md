# Enterprise Expense Management Hub

A Salesforce-based Expense Management application built with **LWC, Apex, Flow, Approval Processes, and Chart.js**.

## Features

- Employee expense submission using LWC
- Manager dashboard with Chart.js analytics
- Inline approve/reject actions
- Automated approval routing with Flow
- Monthly expense aggregation with Scheduled Apex
- Salesforce security with `with sharing` and Private OWD
- Comprehensive Apex test coverage

## Tech Stack

**Frontend:** LWC, SLDS, Chart.js  
**Backend:** Apex, Schedulable Apex  
**Automation:** Flow Builder, Approval Processes  
**Data:** `Expense__c`, `Expense_Category__c`, `Expense_Summary__c`  
**Deployment:** Salesforce CLI, SFDX

## Deployment

```bash
git clone https://github.com/YOUR_USERNAME/salesforce-expense-tracker.git
cd salesforce-expense-tracker

sf org login web
sf project deploy start
```

Run tests:

```bash
sf apex run test --class-names ExpenseAppTest --code-coverage --result-format human
```

## Architecture

```text
[ Employee ] ──► [ expenseSubmitter (LWC) ] ──► [ Expense__c ] ──► [ Flow / Approval Process ]
                                                       │                         │
                                                       │ (Monthly Rollup)        │ (Approve/Reject)
                                                       ▼                         ▼
                                           [ MonthlyExpenseAggregator ]   [ ExpenseController (Apex) ]
                                                       │                         │
                                                       ▼                         ▼
                                            [ Expense_Summary__c ] ───► [ managerDashboard (LWC) ]
                                                                                 ▲
                                                                                 │
                                                                            [ Manager ]
```
