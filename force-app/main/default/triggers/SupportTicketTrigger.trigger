trigger SupportTicketTrigger on Support_Ticket__c (before insert) {
SupportTicketTriggerHandler.handleBeforeInsert(Trigger.new);
}