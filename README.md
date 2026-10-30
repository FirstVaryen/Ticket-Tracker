# Ticket Tracker

A Salesforce Lightning app for logging, triaging and closing customer support tickets. Built with a custom object, Apex trigger logic, a Lightning Web Component dashboard and a record-triggered Flow.

## What it does

- **Support tickets.** The `Support_Ticket__c` object tracks Subject, Description, Priority, Status and the related Contact.
- **Automatic status rules (Apex trigger).** A new ticket with no status starts as `New`. A `High` priority ticket goes straight to `In Progress`.
- **Duplicate prevention.** A contact can't open two tickets with the same subject while one is still open. This runs as one bulk-safe query per batch, with no SOQL inside loops.
- **Support Dashboard (LWC).** `ticketDashboard` lists open tickets and filters them by priority. Clicking a subject opens the record, and the Close button closes the ticket.
- **High-priority alerts (Flow).** `High_Priority_Support_Ticket_Email` sends an email alert when a high-priority ticket is created.

## What's in the repo

| Area | Metadata |
|---|---|
| App | `Ticket_Tracker` (Lightning app with utility bar) |
| Object | `Support_Ticket__c`: fields, list view, page layout |
| Tabs | `Support_Ticket__c`, `Support_Dashboard` |
| Lightning pages | `Ticket_Tracker_Home`, `Support_Dashboard`, `Ticket_Tracker_UtilityBar` |
| LWC | `ticketDashboard` |
| Apex | `TicketController`, `SupportTicketTriggerHandler` + test classes |
| Trigger | `SupportTicketTrigger` |
| Automation | Flow `High_Priority_Support_Ticket_Email`, email alert, email template |

A file-by-file walkthrough of the LWC is in [docs/ticketDashboard-explained.txt](docs/ticketDashboard-explained.txt).

## Deploy to your own org

```bash
sf org login web --alias ticket-tracker
sf project deploy start --manifest manifest/package.xml --target-org ticket-tracker --test-level RunLocalTests
```

Before you deploy, open `force-app/main/default/workflows/Support_Ticket__c.workflow-meta.xml` and replace `YOUR_USERNAME@example.com` with a username from your org. That user receives the high-priority alerts.

## Tech

Salesforce Platform · Apex · Lightning Web Components · Flow · API v62.0
