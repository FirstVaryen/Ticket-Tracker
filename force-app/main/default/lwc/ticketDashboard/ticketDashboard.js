import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpenTickets from '@salesforce/apex/TicketController.getOpenTickets';
import closeTicket from '@salesforce/apex/TicketController.closeTicket';

export default class TicketDashboard extends NavigationMixin(LightningElement) {
    allTickets;
    error;
    closingId;
    wiredTicketsResult;
    filterPriority = 'All';

    get priorityOptions() {
        return [
            { label: 'All Priorities', value: 'All' },
            { label: 'Low', value: 'Low' },
            { label: 'Medium', value: 'Medium' },
            { label: 'High', value: 'High' }
        ];
    }

    handleFilterChange(event) {
        this.filterPriority = event.detail.value;
    }

    @wire(getOpenTickets)
    wiredTickets(result) {
        this.wiredTicketsResult = result;
        if (result.data) {
            this.allTickets = result.data.map((ticket) => ({
                ...ticket,
                priorityClass: 'slds-badge ' + this.priorityBadge(ticket.Priority__c)
            }));
            this.error = undefined;
        } else if (result.error) {
            this.error = this.reduceError(result.error);
            this.allTickets = undefined;
        }
    }

    get tickets() {
        if (!this.allTickets) return undefined;
        if (this.filterPriority === 'All') return this.allTickets;
        return this.allTickets.filter(t => t.Priority__c === this.filterPriority);
    }

    get isLoading() {
        return !this.allTickets && !this.error;
    }

    get hasTickets() {
        return this.tickets && this.tickets.length > 0;
    }

    get isEmpty() {
        return this.tickets && this.tickets.length === 0;
    }

    get cardTitle() {
        const count = this.tickets ? this.tickets.length : 0;
        return `Open Support Tickets (${count})`;
    }

    handleNavigate(event) {
        event.preventDefault();
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    async handleClose(event) {
        const ticketId = event.target.dataset.id;
        this.closingId = ticketId;
        try {
            await closeTicket({ ticketId });
            await refreshApex(this.wiredTicketsResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Ticket closed', variant: 'success' })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Could not close ticket',
                    message: this.reduceError(error),
                    variant: 'error'
                })
            );
        } finally {
            this.closingId = undefined;
        }
    }

    priorityBadge(priority) {
        if (priority === 'High') return 'slds-theme_error';
        if (priority === 'Medium') return 'slds-theme_warning';
        return '';
    }

    reduceError(error) {
        if (error?.body?.message) return error.body.message;
        if (Array.isArray(error?.body)) return error.body.map((e) => e.message).join(', ');
        return error?.message || 'Unknown error';
    }
}