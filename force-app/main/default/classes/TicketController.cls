public with sharing class TicketController {

    @AuraEnabled(cacheable=true)
    public static List<Support_Ticket__c> getOpenTickets() {
        return [
            SELECT Id, Subject__c, Status__c, Priority__c
            FROM Support_Ticket__c
            WHERE Status__c != 'Closed'
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void closeTicket(Id ticketId) {
        Support_Ticket__c ticket = new Support_Ticket__c(
            Id = ticketId,
            Status__c = 'Closed'
        );
        // Runs with the user's own permissions, so someone who cannot edit Status cannot close a ticket here either.
        update as user ticket;
    }
}