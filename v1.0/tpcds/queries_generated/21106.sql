
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city,
           CASE 
               WHEN ca_state IS NULL THEN 'Unknown State'
               ELSE ca_state 
           END AS State_Handled,
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk DESC) AS RowNum
    FROM customer_address
),
SalesCTE AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_paid) AS Total_Sales,
           COUNT(ws_order_number) AS Order_Count
    FROM web_sales
    WHERE ws_sales_price > 0
    GROUP BY ws_bill_customer_sk
),
DemographicsCTE AS (
    SELECT cd_demo_sk, 
           cd_gender, 
           cd_marital_status, 
           MAX(cd_purchase_estimate) AS Max_Purchase_Estimate
    FROM customer_demographics
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
)
SELECT 
    c.c_customer_id,
    a.ca_city,
    a.State_Handled,
    d.cd_gender,
    SUM(s.Total_Sales) AS Total_Web_Sales,
    COALESCE(SUM(s.Order_Count), 0) AS Total_Orders,
    CASE 
        WHEN d.Max_Purchase_Estimate IS NULL THEN 'Low Value Customer'
        ELSE CASE 
            WHEN d.Max_Purchase_Estimate < 1000 THEN 'Medium Value Customer'
            ELSE 'High Value Customer'
        END
    END AS Customer_Value_Category,
    ROW_NUMBER() OVER (PARTITION BY a.ca_city ORDER BY SUM(s.Total_Sales) DESC) AS City_Rank
FROM customer c
LEFT JOIN AddressCTE a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN SalesCTE s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN DemographicsCTE d ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE a.RowNum = 1
GROUP BY c.c_customer_id, a.ca_city, a.State_Handled, d.cd_gender, d.Max_Purchase_Estimate
HAVING SUM(s.Total_Sales) > 0
ORDER BY Total_Web_Sales DESC, City_Rank
LIMIT 50
OFFSET (SELECT COUNT(DISTINCT c_customer_id) / 2 FROM customer);
