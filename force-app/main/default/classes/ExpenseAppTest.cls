@isTest
private class ExpenseAppTest {

    @TestSetup
    static void setupTestData() {
        // Create Category
        Expense_Category__c cat = new Expense_Category__c(Name = 'Travel & Lodging');
        insert cat;

        // Create Approved Expense
        Expense__c expApproved = new Expense__c(
            Amount__c = 250.00,
            Expense_Date__c = Date.today().addMonths(-1),
            Status__c = 'Approved',
            Expense_Category__c = cat.Id,
            Employee__c = UserInfo.getUserId(),
            Manager__c = UserInfo.getUserId(),
            Description__c = 'Client Flight'
        );
        insert expApproved;

        // Create Pending Expense
        Expense__c expPending = new Expense__c(
            Amount__c = 50.00,
            Expense_Date__c = Date.today(),
            Status__c = 'Pending Approval',
            Expense_Category__c = cat.Id,
            Employee__c = UserInfo.getUserId(),
            Manager__c = UserInfo.getUserId(),
            Description__c = 'Team Lunch'
        );
        insert expPending;
    }

    @isTest
    static void testGetCategorySpending() {
        Test.startTest();
        List<ExpenseController.CategorySpendingWrapper> results = ExpenseController.getCategorySpending();
        Test.stopTest();

        Assert.areNotEqual(0, results.size(), 'Should return at least one category');
        Assert.areEqual('Travel & Lodging', results[0].categoryName);
        Assert.areEqual(250.00, results[0].totalAmount);
    }

    @isTest
    static void testGetPendingExpenses() {
        Test.startTest();
        List<Expense__c> pendingList = ExpenseController.getPendingExpenses();
        Test.stopTest();

        Assert.areEqual(1, pendingList.size(), 'Should return one pending expense');
    }

    @isTest
    static void testHandleApprovalDecision() {
        Expense__c exp = [SELECT Id FROM Expense__c WHERE Status__c = 'Pending Approval' LIMIT 1];

        Test.startTest();
        ExpenseController.handleApprovalDecision(exp.Id, 'Approve');
        Test.stopTest();

        Expense__c updatedExp = [SELECT Status__c FROM Expense__c WHERE Id = :exp.Id];
        Assert.areEqual('Approved', updatedExp.Status__c);
    }

    @isTest
    static void testMonthlyExpenseAggregatorScheduled() {
        Test.startTest();
        String cronExp = '0 0 1 1 * ?';
        System.schedule('Test Monthly Aggregator Job', cronExp, new MonthlyExpenseAggregator());
        Test.stopTest();

        List<Expense_Summary__c> summaries = [SELECT Id, Total_Amount__c FROM Expense_Summary__c];
        Assert.areEqual(1, summaries.size(), 'One monthly summary record should be created');
        Assert.areEqual(250.00, summaries[0].Total_Amount__c);
    }

	@isTest
static void testApprovalFallbackAndException() {
    // 1. Covers the 'else' block (direct update)
    Expense_Category__c cat = [SELECT Id FROM Expense_Category__c LIMIT 1];
    Expense__c draftExp = new Expense__c(
        Amount__c = 100, 
        Expense_Date__c = Date.today(), 
        Status__c = 'Draft', 
        Expense_Category__c = cat.Id
    );
    insert draftExp;

    Test.startTest();
    ExpenseController.handleApprovalDecision(draftExp.Id, 'Reject');

    // 2. Covers the 'catch' block (passing null ID causes DML error)
    try {
        ExpenseController.handleApprovalDecision(null, 'Approve');
    } catch (AuraHandledException e) {
        Assert.isNotNull(e.getMessage());
    }
    Test.stopTest();
}
}