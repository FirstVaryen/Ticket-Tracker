@isTest
private class SupportTicketTriggerTest {

    // ---------- Helpers (new) ----------

    private static Contact makeContact() {
        Contact c = new Contact(LastName = 'Tester');
        insert c;
        return c;
    }

    private static Support_Ticket__c makeTicket(String subject, Id contactId, String status) {
        return new Support_Ticket__c(
            Subject__c = subject,
            Contact__c = contactId,
            Priority__c = 'Low',
            Status__c = status
        );
    }

    // ---------- Your existing tests (unchanged) ----------

    @isTest
    static void defaultStatus_isNew() {
        Support_Ticket__c t = new Support_Ticket__c(
            Subject__c = 'Printer not working',
            Priority__c = 'Medium'
        );
        insert t;

        Support_Ticket__c result = [
            SELECT Status__c FROM Support_Ticket__c WHERE Id = :t.Id
        ];
        System.assertEquals('New', result.Status__c, 'Status should default to New');
    }

    @isTest
    static void highPriority_isInProgress() {
        Support_Ticket__c t = new Support_Ticket__c(
            Subject__c = 'Server down',
            Priority__c = 'High',
            Status__c = 'New'
        );
        insert t;

        Support_Ticket__c result = [
            SELECT Status__c FROM Support_Ticket__c WHERE Id = :t.Id
        ];
        System.assertEquals('In Progress', result.Status__c, 'High priority should be In Progress');
    }

    @isTest
    static void bulkInsert_appliesRulesToEveryTicket() {
        List<String> priorities = new List<String>{'Low', 'Medium', 'High', 'High', 'Low'};
        List<Support_Ticket__c> tickets = new List<Support_Ticket__c>();
        for (Integer i = 0; i < priorities.size(); i++) {
            tickets.add(new Support_Ticket__c(
                Subject__c = 'Ticket ' + i,
                Priority__c = priorities[i]
            ));
        }
        insert tickets;

        Map<Id, Support_Ticket__c> results = new Map<Id, Support_Ticket__c>([
            SELECT Priority__c, Status__c FROM Support_Ticket__c
        ]);
        System.assertEquals(5, results.size());
        for (Support_Ticket__c t : results.values()) {
            String expected = (t.Priority__c == 'High') ? 'In Progress' : 'New';
            System.assertEquals(expected, t.Status__c, 'Wrong status for priority ' + t.Priority__c);
        }
    }

    // ---------- Duplicate subject tests (new) ----------

    @isTest
    static void duplicateSubject_forSameContact_isBlocked() {
        Contact c = makeContact();
        insert makeTicket('Printer not working', c.Id, 'New');

        Database.SaveResult result = Database.insert(
            makeTicket('Printer not working', c.Id, 'New'), false
        );

        System.assert(!result.isSuccess(), 'Duplicate should be blocked');
        System.assertEquals(
            'This contact already has an open ticket with this subject.',
            result.getErrors()[0].getMessage()
        );
    }

    @isTest
    static void duplicateSubject_inSameBatch_isBlocked() {
        Contact c = makeContact();
        List<Support_Ticket__c> batch = new List<Support_Ticket__c>{
            makeTicket('Laptop broken', c.Id, 'New'),
            makeTicket('Laptop broken', c.Id, 'New')
        };

        List<Database.SaveResult> results = Database.insert(batch, false);

        System.assert(results[0].isSuccess(), 'First ticket should save');
        System.assert(!results[1].isSuccess(), 'Second duplicate should fail');
    }

    @isTest
    static void sameSubject_afterOriginalClosed_isAllowed() {
        Contact c = makeContact();
        insert makeTicket('Wifi down', c.Id, 'Closed');

        Database.SaveResult result = Database.insert(
            makeTicket('Wifi down', c.Id, 'New'), false
        );

        System.assert(result.isSuccess(), 'Closed tickets should not block a new one');
    }

    @isTest
    static void sameSubject_forDifferentContact_isAllowed() {
        Contact c1 = makeContact();
        Contact c2 = makeContact();
        insert makeTicket('Email issue', c1.Id, 'New');

        Database.SaveResult result = Database.insert(
            makeTicket('Email issue', c2.Id, 'New'), false
        );

        System.assert(result.isSuccess(), 'Different contact should be allowed');
    }

    @isTest
    static void ticketWithoutContact_isIgnoredByDuplicateRule() {
        List<Support_Ticket__c> batch = new List<Support_Ticket__c>{
            makeTicket('No contact', null, 'New'),
            makeTicket('No contact', null, 'New')
        };

        List<Database.SaveResult> results = Database.insert(batch, false);

        System.assert(results[0].isSuccess());
        System.assert(results[1].isSuccess());
    }
}