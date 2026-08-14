import { LightningElement, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/chartjs';
import getCategorySpending from '@salesforce/apex/ExpenseController.getCategorySpending';
import getPendingExpenses from '@salesforce/apex/ExpenseController.getPendingExpenses';
import handleApprovalDecision from '@salesforce/apex/ExpenseController.handleApprovalDecision';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { 
        label: 'Expense #', 
        fieldName: 'expenseUrl', 
        type: 'url',
        typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' },
        initialWidth: 130
    },
    { label: 'Employee', fieldName: 'employeeName', initialWidth: 150 },
    { label: 'Category', fieldName: 'categoryName', initialWidth: 180 },
    { label: 'Amount', fieldName: 'Amount__c', type: 'currency', initialWidth: 120 },
    { label: 'Date', fieldName: 'Expense_Date__c', type: 'date', initialWidth: 130 },
    { label: 'Description', fieldName: 'Description__c', wrapText: true },
    {
        type: 'button',
        fixedWidth: 140,
        typeAttributes: {
            label: 'Approve',
            name: 'approve',
            variant: 'success',
            iconName: 'utility:check'
        }
    },
    {
        type: 'button',
        fixedWidth: 150,
        typeAttributes: {
            label: 'Reject',
            name: 'reject',
            variant: 'destructive',
            iconName: 'utility:close'
        }
    }
];

export default class ManagerDashboard extends LightningElement {
    columns = COLUMNS;
    chart;
    chartjsInitialized = false;

    wiredSpendingResult;
    wiredPendingResult;

    @track spendingData = [];
    @track pendingExpenses = [];
    totalApprovedSpent = 0;

    @wire(getCategorySpending)
    wiredSpending(result) {
        this.wiredSpendingResult = result;
        if (result.data) {
            this.spendingData = result.data;
            this.calculateTotalSpent();
            if (this.chartjsInitialized) {
                this.renderChart();
            }
        }
    }

    @wire(getPendingExpenses)
    wiredPending(result) {
        this.wiredPendingResult = result;
        if (result.data) {
            this.pendingExpenses = result.data.map(row => ({
                ...row,
                expenseUrl: '/' + row.Id,
                employeeName: row.Employee__r ? row.Employee__r.Name : 'N/A',
                categoryName: row.Expense_Category__r ? row.Expense_Category__r.Name : 'Uncategorized'
            }));
        }
    }

    get pendingCount() {
        return this.pendingExpenses ? this.pendingExpenses.length : 0;
    }

    get hasPendingExpenses() {
        return this.pendingExpenses && this.pendingExpenses.length > 0;
    }

    calculateTotalSpent() {
        this.totalApprovedSpent = this.spendingData
            .reduce((sum, item) => sum + (item.totalAmount || 0), 0)
            .toFixed(2);
    }

    renderedCallback() {
        if (this.chartjsInitialized) {
            return;
        }
        this.chartjsInitialized = true;

        loadScript(this, chartjs)
            .then(() => {
                this.renderChart();
            })
            .catch(error => {
                console.error('Error loading ChartJS:', error);
            });
    }

    renderChart() {
        if (!window.Chart || !this.spendingData.length) {
            return;
        }

        const labels = this.spendingData.map(item => item.categoryName);
        const values = this.spendingData.map(item => item.totalAmount);

        const canvas = this.template.querySelector('canvas.donutChart');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');

        if (this.chart) {
            this.chart.destroy();
        }

        this.chart = new window.Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: labels,
                datasets: [{
                    data: values,
                    backgroundColor: ['#0070D2', '#4BCA81', '#FFB75D', '#D4504C', '#9053C7']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                legend: { position: 'bottom' }
            }
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        const decision = actionName === 'approve' ? 'Approve' : 'Reject';

        handleApprovalDecision({ expenseId: row.Id, action: decision })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Expense ${row.Name} has been ${decision.toLowerCase()}d.`,
                        variant: decision === 'Approve' ? 'success' : 'warning'
                    })
                );
                // Refresh datatable & chart dynamically
                return Promise.all([
                    refreshApex(this.wiredPendingResult),
                    refreshApex(this.wiredSpendingResult)
                ]);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error'
                    })
                );
            });
    }
}