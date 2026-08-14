import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import currentUserId from '@salesforce/user/Id';

export default class ExpenseSubmitter extends LightningElement {

    userId = currentUserId; 
    handleSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success!',
                message: 'Expense submitted successfully and routed for manager approval.',
                variant: 'success'
            })
        );

        // Clear input fields after submission
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                if (field.fieldName !== 'Status__c') {
                    field.reset();
                }
            });
        }
    }

    handleError(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Submission Error',
                message: event.detail ? event.detail.message : 'Please check validation rules.',
                variant: 'error'
            })
        );
    }
}