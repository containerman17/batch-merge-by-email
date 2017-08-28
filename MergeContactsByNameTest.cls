@isTest
private class MergeContactsByNameTest {
    @testSetup static void setup(){
        Contact original = new Contact(FirstName = 'Linus', LastName = 'Torvalds', email='father@linux.com');
		Contact copy1 = new Contact(FirstName = 'Linus', LastName='Torvalds', email='foo@bar.com');
        Contact copy2 = new Contact(FirstName = 'Linus', LastName='Torvalds', Department='Development');
        
        List<Contact> toInsert = new List<Contact>();
        toInsert.add(original);
        toInsert.add(copy1);
        toInsert.add(copy2);
        insert toInsert;
        
        Test.setCreatedDate(original.Id, DateTime.newInstance(2017,1,1));
        Test.setCreatedDate(copy1.Id, DateTime.newInstance(1999,1,1));
        Test.setCreatedDate(copy2.Id, DateTime.newInstance(1992,1,1));
        
        Account account = new Account(Name='Test');
        insert account;
        
        copy1.accountId = account.Id;
        update copy1;
    }     

    @isTest static void normalSituation(){        
        Test.startTest();
        MergeContactsByName batch = new MergeContactsByName();
        Database.executeBatch(batch);
        Test.stopTest();
        
        Contact original = [SELECT CreatedDate, Email, Department, AccountId FROM Contact];
        Account account = [SELECT Id FROM Account];
        
        //it should delete old values
        System.assertEquals(1, [SELECT COUNT() FROM Contact]);
        System.assertEquals(DateTime.newInstance(2017,1,1), original.CreatedDate);
        
        //it should copy string values
        System.assertEquals('Development', original.Department);
        
        //it should copy accountId
		System.assertEquals(account.Id, original.AccountId);        
        
        //it should not replace existing values
        System.assertEquals('father@linux.com', original.Email);
    }
}
