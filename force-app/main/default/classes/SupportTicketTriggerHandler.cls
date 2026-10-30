public class SupportTicketTriggerHandler {

    public static void handleBeforeInsert(List<Support_Ticket__c> tickets) {
        applyStatusRules(tickets);
        preventDuplicateSubjects(tickets);
    }

    // BR-001 and BR-002
    private static void applyStatusRules(List<Support_Ticket__c> tickets) {
        for (Support_Ticket__c t : tickets) {
            if (String.isBlank(t.Status__c)) {
                t.Status__c = 'New';
            }
            if (t.Priority__c == 'High') {
                t.Status__c = 'In Progress';
            }
        }
    }

    // New rule: a Contact cannot have two open tickets with the same subject
    private static void preventDuplicateSubjects(List<Support_Ticket__c> tickets) {
        Set<Id> contactIds = new Set<Id>();
        Set<String> subjects = new Set<String>();

        for (Support_Ticket__c t : tickets) {
            if (t.Contact__c != null && String.isNotBlank(t.Subject__c)) {
                contactIds.add(t.Contact__c);
                subjects.add(t.Subject__c.trim());
            }
        }
        if (contactIds.isEmpty()) {
            return;
        }

        // One query for the whole batch, never inside the loop
        Set<String> existingKeys = new Set<String>();
        for (Support_Ticket__c existing : [
            SELECT Contact__c, Subject__c
            FROM Support_Ticket__c
            WHERE Contact__c IN :contactIds
            AND Subject__c IN :subjects
            AND Status__c != 'Closed'
        ]) {
            existingKeys.add(buildKey(existing.Contact__c, existing.Subject__c));
        }

        Set<String> seenInThisBatch = new Set<String>();
        for (Support_Ticket__c t : tickets) {
            if (t.Contact__c == null || String.isBlank(t.Subject__c)) {
                continue;
            }
            String key = buildKey(t.Contact__c, t.Subject__c);
            if (existingKeys.contains(key) || seenInThisBatch.contains(key)) {
                t.Subject__c.addError('This contact already has an open ticket with this subject.');
            } else {
                seenInThisBatch.add(key);
            }
        }
    }

    private static String buildKey(Id contactId, String subject) {
        return contactId + '|' + subject.trim().toLowerCase();
    }
}