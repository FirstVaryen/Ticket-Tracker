@isTest
private class TicketControllerTest {

    private static Support_Ticket__c makeTicket(String subject, String priority, String status) {
        return new Support_Ticket__c(
            Subject__c = subject,
            Priority__c = priority,
            Status__c = status
        );
    }

    @isTest
    static void getOpenTickets_returnsOnlyOpenTickets() {
        insert new List<Support_Ticket__c>{
            makeTicket('Open ticket', 'Low', 'New'),
            makeTicket('Closed ticket', 'Low', 'Closed')
        };

        Test.startTest();
        List<Support_Ticket__c> results = TicketController.getOpenTickets();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Only the open ticket should be returned');
        System.assertEquals('Open ticket', results[0].Subject__c);
    }

    @isTest
    static void closeTicket_setsStatusToClosed() {
        Support_Ticket__c ticket = makeTicket('Printer not working', 'Medium', 'New');
        insert ticket;

        Test.startTest();
        TicketController.closeTicket(ticket.Id);
        Test.stopTest();

        Support_Ticket__c updated = [
            SELECT Status__c FROM Support_Ticket__c WHERE Id = :ticket.Id
        ];
        System.assertEquals('Closed', updated.Status__c, 'Ticket should be Closed');
    }

    @isTest
    static void getOpenTickets_handlesMultipleTickets() {
        List<Support_Ticket__c> tickets = new List<Support_Ticket__c>();
        for (Integer i = 0; i < 5; i++) {
            tickets.add(makeTicket('Ticket ' + i, 'Low', 'New'));
        }
        insert tickets;

        List<Support_Ticket__c> results = TicketController.getOpenTickets();

        System.assertEquals(5, results.size(), 'All five open tickets should be returned');
    }
}