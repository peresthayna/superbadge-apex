@isTest
public class WarehouseCalloutServiceMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('[{"name": "Test Equipment","sku": "12345","quantity": 10,"maintenanceperiod": 12,"lifespan": 24,"cost": 150.0,"replacement": true}]');
        response.setStatusCode(200);
        return response;
    }
}
