public with sharing class MonthlyExpenseAggregator implements Schedulable {

    public void execute(SchedulableContext sc) {
        aggregateMonthlyExpenses();
    }

    public static void aggregateMonthlyExpenses() {
        // Aggregate for current/past month records
        Date targetDate = Date.today().addMonths(-1);
        Integer targetMonth = targetDate.month();
        Integer targetYear = targetDate.year();

        List<AggregateResult> groupedResults = [
            SELECT Employee__c empId, SUM(Amount__c) totalSpent
            FROM Expense__c
            WHERE Status__c = 'Approved' 
            AND CALENDAR_MONTH(Expense_Date__c) = :targetMonth 
            AND CALENDAR_YEAR(Expense_Date__c) = :targetYear
            GROUP BY Employee__c
        ];

        List<Expense_Summary__c> summariesToInsert = new List<Expense_Summary__c>();
        String monthYearStr = String.valueOf(targetYear) + '-' + (targetMonth < 10 ? '0' + String.valueOf(targetMonth) : String.valueOf(targetMonth));

        for (AggregateResult ar : groupedResults) {
            Id empId = (Id)ar.get('empId');
            Decimal total = (Decimal)ar.get('totalSpent');

            if (empId != null) {
                summariesToInsert.add(new Expense_Summary__c(
                    Employee__c = empId,
                    Total_Amount__c = total,
                    Month_Year__c = monthYearStr
                ));
            }
        }

        if (!summariesToInsert.isEmpty()) {
            insert summariesToInsert;
        }
    }
}