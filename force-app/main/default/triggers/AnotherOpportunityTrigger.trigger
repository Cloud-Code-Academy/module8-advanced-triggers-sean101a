/*
AnotherOpportunityTrigger Overview

This trigger was initially created for handling various events on the Opportunity object. It was developed by a prior developer and has since been noted to cause some issues in our org.

IMPORTANT:
- This trigger does not adhere to Salesforce best practices.
- It is essential to review, understand, and refactor this trigger to ensure maintainability, performance, and prevent any inadvertent issues.

ISSUES:
Avoid nested for loop - 1 instance
Avoid DML inside for loop - 1 instance
Bulkify Your Code - 1 instance
Avoid SOQL Query inside for loop - 2 instances
Stop recursion - 1 instance

RESOURCES: 
https://www.salesforceben.com/12-salesforce-apex-best-practices/
https://developer.salesforce.com/blogs/developer-relations/2015/01/apex-best-practices-15-apex-commandments
*/
trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    /*public static Boolean runOnce = true;
    if (!runOnce) {
        return;
    }
    runOnce = false;

    if (trigger.isBefore) {
        if (Trigger.isInsert) {
            // Set default Type for new Opportunities
            for (Opportunity opp : Trigger.new) {
                if (opp.Type == null) {
                    opp.Type = 'New Customer';
                }
            }
        } else if (Trigger.isDelete) {
            // Prevent deletion of closed Opportunities
            for (Opportunity oldOpp : Trigger.old) {
                if (oldOpp.IsClosed) {
                    oldOpp.addError('Cannot delete closed opportunity');
                }
            }
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            // Create a new Task for newly inserted Opportunities
            List<Task> tasksToInsert = new List<Task>();
            for (Opportunity opp : Trigger.new) {
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                tasksToInsert.add(tsk);
            }
            if (!tasksToInsert.isEmpty()) {
                insert tasksToInsert;
            }
        } else if (Trigger.isUpdate) {
            // Append Stage changes in Opportunity Description
            for (Integer i = 0; i < Trigger.new.size(); i++) {
                Opportunity newOpp = Trigger.new[i];
                Opportunity oldOpp = Trigger.old[i];
                if (newOpp.StageName != oldOpp.StageName) {
                    newOpp.Description += '\n Stage Change: ' + newOpp.StageName;
                }
            }
        } else if (Trigger.isDelete) {
            // Send email notifications when an Opportunity is deleted
            notifyOwnersOpportunityDeleted(Trigger.old);
        } else if (Trigger.isUndelete) {
            // Assign the primary contact to undeleted Opportunities
            assignPrimaryContact(Trigger.newMap);
        }
    }

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    /*private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : opps) {
            ownerIds.add(opp.OwnerId);
        }
        Map<Id, User> owners = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :ownerIds]);

        for (Opportunity opp : opps) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (owners.containsKey(opp.OwnerId)) {
                String[] toAddresses = new String[] { owners.get(opp.OwnerId).Email };
                mail.setToAddresses(toAddresses);
                mail.setSubject('Opportunity Deleted: ' + opp.Name);
                mail.setPlainTextBody('Your Opportunity: ' + opp.Name + ' has been deleted.');
                mails.add(mail);
            }
        }
        if (!mails.isEmpty()) {
            try {
                Messaging.sendEmail(mails);
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
            }
        }
    }

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    /*private static void assignPrimaryContact(Map<Id, Opportunity> oppNewMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : oppNewMap.values()) {
            if (opp.Primary_Contact__c == null) {
                accountIds.add(opp.AccountId);
            }
        }

        Map<Id, Contact> primaryContacts = new Map<Id, Contact>(
            [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId IN :accountIds]
        );

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : oppNewMap.values()) {
            if (opp.Primary_Contact__c == null && primaryContacts.containsKey(opp.AccountId)) {
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = primaryContacts.get(opp.AccountId).Id;
                oppsToUpdate.add(oppToUpdate);
            }
        }

        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }*/
}