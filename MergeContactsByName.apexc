global class MergeContactsByName implements Database.Batchable<String>, Database.Stateful {
    
    List<String> fieldsToMerge = null;
    
    global Integer recordsProcessed = 0;
    
    global Iterable<String> start (Database.BatchableContext BC){
        //we have only several thouthands of records. so it is ok
        //for millions of records use AggregateResultIterable 
        //https://www.xgeek.net/salesforce/using-aggregate-soql-queries-results-in-batch-apex/
        
        List<String> result = new List<String>();
        for(AggregateResult row: [SELECT Name FROM Contact GROUP BY Name HAVING COUNT(Id) > 1]){
            result.add((String)row.get('Name'));
        }
        return result;
    }   
    
    global void execute(Database.BatchableContext bc, List<String> names){
        List<Contact> forDelete = new List<Contact>();
        List<Contact> forUpdate = new List<Contact>();
        
        //construct query
        List<String> fieldsForMerge = getFieldsForMerge();
        String query = 'SELECT Id, Name, ' + join(fieldsForMerge, ',') + ' FROM CONTACT WHERE Name IN :names ORDER BY CreatedDate DESC';
        
        List<Contact> rawContactsList = Database.query(query);
        
        //group contacts by name
        Map<String, List<Contact>> contactsGrouped = groupContactsByName(rawContactsList);
        
        //for each group
        for(String name: contactsGrouped.keySet()){
            List<Contact> contactsToMerge = contactsGrouped.get(name);
            //the lastest one should stay, other ones should be deleted
            Contact newestContact = contactsToMerge.get(0);
            contactsToMerge.remove(0);
            
            //merge information from rest contacts
            for(Contact contact: contactsToMerge){
                newestContact = mergeContacts(contact, newestContact);
                forDelete.add(contact);
            }
            
            forUpdate.add(newestContact);
        }
        
       
        delete forDelete;
        updateDML(forUpdate);
    } 
    
    //update with ignore duplicates option
    void updateDML(List<sObject> items){
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.DuplicateRuleHeader.AllowSave = true; 
        
        List<Database.SaveResult> results = Database.update(items, dmlOptions); 
        
        for(Database.SaveResult result: results){
            if (!result.isSuccess()) {   
                System.debug('Error on updating items'); 
                System.assert(false);
            }
        }
    }
    
    String join(List<String> values, String delimeter) {
        List<String> valueCopy = new List<String>(values);
        if(valueCopy.isEmpty()){
            return null;
        }
        String result = valueCopy[0];
        valueCopy.remove(0);
        while(!valueCopy.isEmpty()) {
            result += delimeter + valueCopy[0];
            valueCopy.remove(0);
        }
        return result;
    }
    
    Contact mergeContacts(Contact source, Contact destination){
        List<String> fieldsForMerge = getFieldsForMerge();
        
        for(String fieldName: fieldsForMerge){
            Object oldValue = destination.get(fieldName);
            if(oldValue == null || oldValue == ''){
                destination.put(fieldName, source.get(fieldName));
            }
        }
        return destination;
    }
    
    List<String> getFieldsForMerge(){   
        //describe calls are heavy, lets cache them
        if(fieldsToMerge == null){
            fieldsToMerge = new List<String>();
            for(SObjectField field: Contact.getSObjectType().getDescribe().fields.getMap().values()){
                Schema.DescribeFieldResult fieldDescribed = field.getDescribe();
                
                //every field that could be changed
                if(fieldDescribed.isUpdateable()){
                    fieldsToMerge.add(fieldDescribed.getName());
                }
            }
        }
        
        return fieldsToMerge;
    }
    
    Map<String, List<Contact>> groupContactsByName(List<Contact> rawContactsList){
        Map<String, List<Contact>> contactsGrouped = new Map<String, List<Contact>>();
        
        for(Contact contact: rawContactsList){
            if(!contactsGrouped.containsKey(contact.Name)){
                contactsGrouped.put(contact.Name, new List<Contact>());
            }
            contactsGrouped.get(contact.Name).add(contact);
        }
        
        return contactsGrouped;
    }
    
    global void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + ' records processed. Shazam!');
    }    
}
