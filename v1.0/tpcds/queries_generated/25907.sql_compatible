
WITH CustomerAddresses AS (
    SELECT 
        ca_address_id,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number != '' THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS Full_Address,
        TRIM(ca_city) AS Cleaned_City,
        TRIM(ca_state) AS Cleaned_State,
        TRIM(ca_zip) AS Cleaned_Zip
    FROM customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        TRIM(cd_gender) AS Cleaned_Gender,
        TRIM(cd_marital_status) AS Cleaned_Marital_Status,
        UPPER(TRIM(cd_education_status)) AS Cleaned_Education_Status
    FROM customer_demographics
),
DailySales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS Total_Sales,
        COUNT(ws_order_number) AS Order_Count,
        AVG(ws_sales_price) AS Average_Sales_Per_Order
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
EnhancedSalesData AS (
    SELECT 
        cs.bill_customer_sk,
        cd.Cleaned_Gender,
        cd.Cleaned_Marital_Status,
        cd.Cleaned_Education_Status,
        ca.Full_Address,
        ds.Total_Sales,
        ds.Order_Count,
        ds.Average_Sales_Per_Order
    FROM CustomerDemographics cd
    JOIN DailySales ds ON cd.cd_demo_sk = ds.ws_bill_customer_sk
    JOIN CustomerAddresses ca ON cd.cd_demo_sk = ca.ca_address_id
)
SELECT 
    esd.Cleaned_Gender,
    esd.Cleaned_Marital_Status,
    esd.Cleaned_Education_Status,
    COUNT(*) AS Number_of_Customers,
    AVG(esd.Total_Sales) AS Average_Total_Sales,
    SUM(esd.Order_Count) AS Total_Orders,
    SUM(esd.Average_Sales_Per_Order) AS Total_Average_Sales_Per_Order
FROM EnhancedSalesData esd
WHERE esd.Total_Sales > 1000
GROUP BY esd.Cleaned_Gender, esd.Cleaned_Marital_Status, esd.Cleaned_Education_Status
ORDER BY Average_Total_Sales DESC;
