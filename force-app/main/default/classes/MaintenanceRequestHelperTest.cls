@isTest
public with sharing class MaintenanceRequestHelperTest {
    @isTest
    public static void testUpdateWorkOrdersPositive() {
        Product2 newEquipment = new Product2(
            Name = 'Filtro',
            Maintenance_Cycle__c = 10,
            IsActive = true,
            Replacement_Part__c = true,
            Warehouse_SKU__c = 'SKU123'
        );
        Database.insert(newEquipment);

        Vehicle__c newVehicle = new Vehicle__c(Name = '123ABC');
        Database.insert(newVehicle);

        Case newCase = new Case(
            Type = 'Routine Maintenance',
            Status = 'New',
            Vehicle__c = newVehicle.Id
        );
        Database.insert(newCase);
        newCase.Status = 'Closed';
        Database.update(newCase);

        Equipment_Maintenance_Item__c item = new Equipment_Maintenance_Item__c(
            Equipment__c = newEquipment.Id,
            Maintenance_Request__c = newCase.Id
        );
        Database.insert(item);

        Test.startTest();
        MaintenanceRequestHelper.updateWorkOrders(new List<Case>{newCase});
        Test.stopTest();

        List<Case> lCases = [SELECT Id, ParentId, Status, Subject FROM Case WHERE ParentId = :newCase.Id];
        Assert.areEqual('New', lCases[0].Status);
        Assert.areEqual('Routine Maintenance', lCases[0].Subject);
    }

    @isTest
    public static void testUpdateWorkOrdersNegative() {
        Vehicle__c newVehicle = new Vehicle__c(Name = '123ABC');
        Database.insert(newVehicle);
        
        Case newCase = new Case(
            Type = 'Other',
            Status = 'Closed',
            Vehicle__c = newVehicle.Id
        );
        Database.insert(newCase);

        Test.startTest();
        MaintenanceRequestHelper.updateWorkOrders(new List<Case>{newCase});
        Test.stopTest();

        List<Case> lCases = [SELECT Id FROM Case WHERE ParentId = :newCase.Id];
        Assert.isFalse(lCases.size()>0);
    }

    @isTest
    public static void testUpdateWorkOrdersBulk() {
        List<Case> lCases = new List<Case>();
        List<Equipment_Maintenance_Item__c> lItems = new List<Equipment_Maintenance_Item__c>();

        Product2 newEquipment = new Product2(
            Name = 'Peça',
            Maintenance_Cycle__c = 5,
            IsActive = true,
            Replacement_Part__c = true,
            Warehouse_SKU__c = 'SKU999'
        );
        Database.insert(newEquipment);

        Vehicle__c newVehicle = new Vehicle__c(Name = '123ABC');
        Database.insert(newVehicle);

        for (Integer i = 0; i < 300; i++) {
            Case newCase = new Case(Type = 'Repair', Status = 'Closed', Vehicle__c = newVehicle.Id);
            lCases.add(newCase);
        }
        Database.insert(lCases);

        for (Case oCase: lCases) {
            Equipment_Maintenance_Item__c item = new Equipment_Maintenance_Item__c(
                Equipment__c = newEquipment.Id,
                Maintenance_Request__c = oCase.Id
            );
            lItems.add(item);
        }
        Database.insert(lItems);

        Test.startTest();
        MaintenanceRequestHelper.updateWorkOrders(lCases);
        Test.stopTest();

        List<Case> newCases = [SELECT Id, ParentId FROM Case WHERE ParentId IN :lCases];
        Assert.areEqual(300, newCases.size());
    }
}