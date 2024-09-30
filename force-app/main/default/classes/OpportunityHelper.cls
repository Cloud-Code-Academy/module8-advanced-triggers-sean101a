public with sharing class OpportunityHelper {
    public static Boolean isTriggerExecuted = false;

    // Validate Opportunity Amount
    public static void oppAmount(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if (opp.Amount < 5000) {
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    // Prevent Deletion of Closed Won Opportunities for Banking Industry
    public static void oppDelete(List<Opportunity> opps) {
        Map<Id, Account> accounts = new Map<Id, Account>(
            [SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :Trigger.old)]
        );

        for (Opportunity opp : opps) {
            if (opp.StageName == 'Closed Won' && accounts.get(opp.AccountId).Industry == 'Banking') {
                opp.addError('Cannot delete closed opportunity');
            }
        }
    }

    // Assign Primary Contact to Opportunities based on CEO Title
    public static void oppUpdate(List<Opportunity> opps) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opps) {
            accountIds.add(opp.AccountId);
        }

        Map<Id, Contact> contacts = new Map<Id, Contact>(
            [SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]
        );

        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for (Opportunity opp : opps) {
            if (opp.Primary_Contact__c == null && accountIdToContact.containsKey(opp.AccountId)) {
                opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
            }
        }
    }

    // Set Default Opportunity Type
    public static void setDefaultOpportunityType(List<Opportunity> newOpportunities) {
        for (Opportunity opp : newOpportunities) {
            if (opp.Type == null) {
                opp.Type = 'New Customer';
            }
        }
    }

    // Prevent Closed Won Opportunity Deletion
    public static void preventClosedOpportunityDeletion(List<Opportunity> oldOpportunities) {
        for (Opportunity oldOpp : oldOpportunities) {
            if (oldOpp.IsClosed && oldOpp.StageName == 'Closed Won') {
                oldOpp.addError('Cannot delete closed opportunity');
            }
        }
    }

    // Create Task for New Opportunities
    public static void createTasksForNewOpportunities(List<Opportunity> newOpportunities) {
        List<Task> tasksToInsert = new List<Task>();
        for (Opportunity opp : newOpportunities) {
            Task tsk = new Task(
                Subject = 'Call Primary Contact',
                WhatId = opp.Id,
                WhoId = opp.Primary_Contact__c,
                OwnerId = opp.OwnerId,
                ActivityDate = Date.today().addDays(3)
            );
            tasksToInsert.add(tsk);
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    // Append Stage Change to Description
    public static void appendStageChangeToDescription(List<Opportunity> newOpportunities, List<Opportunity> oldOpportunities) {
        for (Integer i = 0; i < newOpportunities.size(); i++) {
            Opportunity newOpp = newOpportunities[i];
            Opportunity oldOpp = oldOpportunities[i];

            if (newOpp.StageName != oldOpp.StageName) {
                newOpp.Description = (String.isBlank(oldOpp.Description) ? '' : oldOpp.Description + '\n') + 'Stage Change:' + newOpp.StageName;
            }
        }
    }

    // Notify Owners of Deleted Opportunities
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> deletedOpportunities) {
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : deletedOpportunities) {
            ownerIds.add(opp.OwnerId);
        }

        Map<Id, User> owners = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :ownerIds]);

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : deletedOpportunities) {
            if (owners.containsKey(opp.OwnerId)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { owners.get(opp.OwnerId).Email });
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

    // Assign VP Sales as Primary Contact
    public static void assignPrimaryContact(Map<Id, Opportunity> oppNewMap) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();

        for (Opportunity opp : oppNewMap.values()) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
                oppIds.add(opp.Id);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        List<Contact> contacts = [SELECT Id, AccountId, Title FROM Contact WHERE AccountId IN :accountIds];

        Map<Id, Contact> primaryContacts = new Map<Id, Contact>();
        for (Contact contact : contacts) {
            if (contact.Title != null && contact.Title.equalsIgnoreCase('VP Sales')) {
                primaryContacts.put(contact.AccountId, contact);
            }
        }

        if (primaryContacts.isEmpty()) {
            return;
        }

        List<Opportunity> oppsToUpdate = [SELECT Id, Primary_Contact__c, AccountId FROM Opportunity WHERE Id IN :oppIds];

        for (Opportunity opp : oppsToUpdate) {
            if (primaryContacts.containsKey(opp.AccountId)) {
                opp.Primary_Contact__c = primaryContacts.get(opp.AccountId).Id;
            }
        }

        if (!oppsToUpdate.isEmpty()) {
            try {
                update oppsToUpdate;
            } catch (DmlException e) {
                System.debug('Exception during update: ' + e.getMessage());
            }
        }
    }
}