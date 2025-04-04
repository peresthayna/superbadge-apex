public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {

    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';

    public void execute(QueueableContext context) {
        runWarehouseEquipmentSync();
    }

    public void runWarehouseEquipmentSync() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            List<Object> lResults = (List<Object>) JSON.deserializeUntyped(response.getBody());
            List<Product2> lEquipment = new List<Product2>();

            for (Object result: lResults) {
                Map<String, Object> mResults = (Map<String, Object>) result;

                Product2 newProduct = new Product2();
                newProduct.Replacement_Part__c = true;
                newProduct.Name = (String) mResults.get('name');
                newProduct.Maintenance_Cycle__c = (Integer) mResults.get('maintenanceperiod');
                newProduct.Lifespan_Months__c = (Integer) mResults.get('lifespan');
                newProduct.Cost__c = (Decimal) mResults.get('cost');
                newProduct.Warehouse_SKU__c = (String) mResults.get('sku');
                newProduct.Current_Inventory__c = ((Decimal) mResults.get('quantity')).intValue();

                lEquipment.add(newProduct);
            }

            if (!lEquipment.isEmpty()) {
                Database.upsert(lEquipment, Product2.Warehouse_SKU__c, false);
            }
        }
    }
}
