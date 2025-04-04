public with sharing class MaintenanceRequestHelper {

    public static final String TYPE_REPAIR = 'Repair';
    public static final String TYPE_ROUTINE_MAINTENANCE = 'Routine Maintenance';
    public static final String STATUS_CLOSED = 'Closed';
    public static final String STATUS_NEW = 'New';
    public static final String ORIGIN_WEB = 'New';

    public static void updateWorkOrders(List<Case> lCases) {
        List<Case> lNewCases = new List<Case>();
        Map<Id, Case> oldToNewCaseMap = new Map<Id, Case>();
    
        Map<Id, List<Equipment_Maintenance_Item__c>> caseToEquipments = new Map<Id, List<Equipment_Maintenance_Item__c>>();
        List<Equipment_Maintenance_Item__c> allItems = [
            SELECT Equipment__c, Equipment__r.Maintenance_Cycle__c, Maintenance_Request__c
            FROM Equipment_Maintenance_Item__c
            WHERE Maintenance_Request__c IN :lCases
        ];
    
        for (Equipment_Maintenance_Item__c item : allItems) {
            if (!caseToEquipments.containsKey(item.Maintenance_Request__c)) {
                caseToEquipments.put(item.Maintenance_Request__c, new List<Equipment_Maintenance_Item__c>());
            }
            caseToEquipments.get(item.Maintenance_Request__c).add(item);
        }
    
        for(Case oldCase: lCases) {
            if((oldCase.Type == TYPE_REPAIR || oldCase.Type == TYPE_ROUTINE_MAINTENANCE) && oldCase.Status == STATUS_CLOSED) {
                Integer shortestCycle = getShortestCycleFromMap(oldCase.Id, caseToEquipments);
    
                Case newCase = new Case(
                    Type = TYPE_ROUTINE_MAINTENANCE,
                    ParentId = oldCase.Id,
                    Status = STATUS_NEW,
                    Subject = TYPE_ROUTINE_MAINTENANCE,
                    Origin = ORIGIN_WEB,
                    Vehicle__c = oldCase.Vehicle__c,
                    Date_Reported__c = System.today(),
                    Date_Due__c = System.today().addDays(shortestCycle)
                );
                lNewCases.add(newCase);
            }
        }
    
        Database.insert(lNewCases);
    
        for (Integer i = 0; i < lNewCases.size(); i++) {
            oldToNewCaseMap.put(lCases[i].Id, lNewCases[i]);
        }
    
        List<Equipment_Maintenance_Item__c> newItems = new List<Equipment_Maintenance_Item__c>();
        for (Equipment_Maintenance_Item__c oldItem : allItems) {
            Id oldCaseId = oldItem.Maintenance_Request__c;
            if (oldToNewCaseMap.containsKey(oldCaseId)) {
                newItems.add(new Equipment_Maintenance_Item__c(
                    Equipment__c = oldItem.Equipment__c,
                    Maintenance_Request__c = oldToNewCaseMap.get(oldCaseId).Id
                ));
            }
        }
    
        Database.insert(newItems);
    }
    
    private static Integer getShortestCycleFromMap(Id caseId, Map<Id, List<Equipment_Maintenance_Item__c>> caseToEquipments) {
        Integer shortestCycle = 9999;
        if (caseToEquipments.containsKey(caseId)) {
            for (Equipment_Maintenance_Item__c item : caseToEquipments.get(caseId)) {
                Integer cycle = (Integer) item.Equipment__r.Maintenance_Cycle__c;
                if (cycle != null && cycle < shortestCycle) {
                    shortestCycle = cycle;
                }
            }
        }
        return shortestCycle == 9999 ? 0 : shortestCycle;
    }    
}