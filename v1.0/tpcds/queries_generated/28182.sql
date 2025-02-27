
WITH Address_Info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Address,
        ca_city,
        ca_state,
        ma.city AS Merchant_City,
        ma.state AS Merchant_State
    FROM customer_address AS ca
    INNER JOIN (
        SELECT 
            s_store_sk, 
            s_city AS city,
            s_state AS state
        FROM store
    ) AS ma ON ma.s_store_sk = ca.ca_address_sk
),
Customer_Demo AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS Gender,
        CONCAT(cd_education_status, ' (', cd_marital_status, ')') AS Education_Status
    FROM customer_demographics
),
Sales_Data AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_net_paid) AS Total_Sales,
        COUNT(ws.ws_order_number) AS Order_Count
    FROM web_sales AS ws
    GROUP BY ws.bill_customer_sk
)
SELECT 
    cd.cd_demo_sk,
    cd.Gender,
    cd.Education_Status,
    ai.Full_Address,
    ai.ca_city,
    ai.ca_state,
    sd.Total_Sales,
    sd.Order_Count,
    CASE 
        WHEN sd.Total_Sales > 1000 THEN 'Premium'
        WHEN sd.Total_Sales BETWEEN 500 AND 1000 THEN 'Standard'
        ELSE 'Basic'
    END AS Customer_Category
FROM Customer_Demo AS cd
LEFT JOIN Address_Info AS ai ON cd.cd_demo_sk = c_current_cdemo_sk
LEFT JOIN Sales_Data AS sd ON cd.cd_demo_sk = sd.bill_customer_sk
WHERE ai.ca_state = 'CA'
ORDER BY sd.Total_Sales DESC;
