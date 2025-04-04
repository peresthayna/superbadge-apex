public with sharing class MaintenanceRequestHelper {

    public static final String TYPE_REPAIR = 'Repair';
    public static final String TYPE_ROUTINE_MAINTENANCE = 'Routine Maintenance';
    public static final String STATUS_CLOSED = 'Closed';
    public static final String STATUS_NEW = 'New';
    public static final String ORIGIN_WEB = 'Web';

    public static void updateWorkOrders(List<Case> lCases) {
        List<Case> lNewCases = new List<Case>();
        Map<Id, Case> mOldToNewCases = new Map<Id, Case>();
    
        Map<Id, List<Equipment_Maintenance_Item__c>> mCaseToEquipment = new Map<Id, List<Equipment_Maintenance_Item__c>>();
        List<Equipment_Maintenance_Item__c> lItems = [
            SELECT Equipment__c, Equipment__r.Maintenance_Cycle__c, Maintenance_Request__c
            FROM Equipment_Maintenance_Item__c
            WHERE Maintenance_Request__c IN :lCases
        ];
    
        for (Equipment_Maintenance_Item__c item: lItems) {
            if (!mCaseToEquipment.containsKey(item.Maintenance_Request__c)) {
                mCaseToEquipment.put(item.Maintenance_Request__c, new List<Equipment_Maintenance_Item__c>());
            }
            mCaseToEquipment.get(item.Maintenance_Request__c).add(item);
        }
    
        for(Case oldCase: lCases) {
            if((oldCase.Type == TYPE_REPAIR || oldCase.Type == TYPE_ROUTINE_MAINTENANCE) && oldCase.Status == STATUS_CLOSED) {
                Integer shortestCycle = getShortestCycleFromMap(oldCase.Id, mCaseToEquipment);
    
                Case newCase = new Case(
                    Type = TYPE_ROUTINE_MAINTENANCE,
                    Status = STATUS_NEW,
                    Subject = TYPE_ROUTINE_MAINTENANCE,
                    Origin = ORIGIN_WEB,
                    ParentId = oldCase.Id,
                    Vehicle__c = oldCase.Vehicle__c,
                    Date_Reported__c = System.today(),
                    Date_Due__c = System.today().addDays(shortestCycle)
                );
                lNewCases.add(newCase);
            }
        }
    
        Database.insert(lNewCases);
    
        for (Case newCase: lNewCases) {
            mOldToNewCases.put(newCase.Id, newCase);
        }
    
        List<Equipment_Maintenance_Item__c> lNewItems = new List<Equipment_Maintenance_Item__c>();
        for (Equipment_Maintenance_Item__c oldItem: lItems) {
            Id oldCaseId = oldItem.Maintenance_Request__c;
            if (mOldToNewCases.containsKey(oldCaseId)) {
                lNewItems.add(new Equipment_Maintenance_Item__c(
                    Equipment__c = oldItem.Equipment__c,
                    Maintenance_Request__c = mOldToNewCases.get(oldCaseId).Id
                ));
            }
        }
    
        Database.insert(lNewItems);
    }
    
    private static Integer getShortestCycleFromMap(Id caseId, Map<Id, List<Equipment_Maintenance_Item__c>> mCaseToEquipment) {
        Integer shortestCycle = 9999;
        if (mCaseToEquipment.containsKey(caseId)) {
            for (Equipment_Maintenance_Item__c item: mCaseToEquipment.get(caseId)) {
                Integer cycle = (Integer) item.Equipment__r.Maintenance_Cycle__c;
                if (cycle != null && cycle < shortestCycle) {
                    shortestCycle = cycle;
                }
            }
        }
        return shortestCycle == 9999 ? 0 : shortestCycle;
    }    
}