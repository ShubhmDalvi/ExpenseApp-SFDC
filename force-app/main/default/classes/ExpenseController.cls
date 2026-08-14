public with sharing class ExpenseController {

    // 1. Get Category Spending for Chart.js
    @AuraEnabled(cacheable=true)
    public static List<CategorySpendingWrapper> getCategorySpending() {
        List<CategorySpendingWrapper> results = new List<CategorySpendingWrapper>();
        
        List<AggregateResult> aggResults = [
            SELECT Expense_Category__r.Name catName, SUM(Amount__c) totalAmount
            FROM Expense__c
            WHERE Status__c = 'Approved'
            GROUP BY Expense_Category__r.Name
        ];
        
        for (AggregateResult ar : aggResults) {
            String name = (String)ar.get('catName');
            Decimal total = (Decimal)ar.get('totalAmount');
            results.add(new CategorySpendingWrapper(
                name != null ? name : 'Uncategorized', 
                total != null ? total : 0
            ));
        }
        return results;
    }

    // 2. Get Pending Approvals for Datatable
    @AuraEnabled(cacheable=true)
    public static List<Expense__c> getPendingExpenses() {
        return [
            SELECT Id, Name, Amount__c, Expense_Date__c, Description__c, 
                   Expense_Category__r.Name, Employee__r.Name, Status__c
            FROM Expense__c
            WHERE Status__c = 'Pending Approval'
            ORDER BY Expense_Date__c DESC
        ];
    }

    // 3. One-Click Approve or Reject from LWC
    @AuraEnabled
    public static void handleApprovalDecision(Id expenseId, String action) {
        try {
            // Find active approval work item
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :expenseId
                LIMIT 1
            ];

            if (!workItems.isEmpty()) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItems[0].Id);
                req.setAction(action); // 'Approve' or 'Reject'
                Approval.process(req);
            } else {
                // Direct update fallback
                Expense__c exp = new Expense__c(
                    Id = expenseId,
                    Status__c = (action == 'Approve') ? 'Approved' : 'Rejected'
                );
                update exp;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error processing approval: ' + e.getMessage());
        }
    }

    // Wrapper Class for clean Chart.js formatting
    public class CategorySpendingWrapper {
        @AuraEnabled public String categoryName { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }

        public CategorySpendingWrapper(String categoryName, Decimal totalAmount) {
            this.categoryName = categoryName;
            this.totalAmount = totalAmount;
        }
    }
}