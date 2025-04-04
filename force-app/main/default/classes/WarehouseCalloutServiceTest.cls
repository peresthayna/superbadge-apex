@isTest
public class WarehouseCalloutServiceTest {
    @isTest
    static void testWarehouseCallout() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());

        Test.startTest();
        System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();

        Product2 equipment = [
            SELECT Id, Name, Warehouse_SKU__c, Current_Inventory__c, Replacement_Part__c
            FROM Product2
            WHERE Warehouse_SKU__c = '12345'
            LIMIT 1
        ];

        Assert.areEqual('Test Equipment', equipment.Name);
        Assert.areEqual(10, equipment.Current_Inventory__c);
        Assert.areEqual(true, equipment.Replacement_Part__c);
    }
}
