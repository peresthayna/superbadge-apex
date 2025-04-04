@isTest
public with sharing class WarehouseSyncScheduleTest {
    @isTest
    static void testScheduleJobRunsSuccessfully() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        String jobName = 'WarehouseSyncScheduleJob_Test';

        Test.startTest();
        String jobId = System.schedule(jobName, '0 0 1 * * ?', new WarehouseSyncSchedule());
        Test.stopTest();

        CronTrigger cronTrigger = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime 
            FROM CronTrigger 
            WHERE Id = :jobId
        ];

        Assert.areEqual('0 0 1 * * ?', cronTrigger.CronExpression);
    }
}
