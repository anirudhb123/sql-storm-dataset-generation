
WITH RECURSIVE RevenueCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS Total_Sales,
        COUNT(ws_order_number) AS Order_Count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS Rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
SalesSummary AS (
    SELECT 
        ca_city,
        SUM(Total_Sales) AS City_Total_Sales,
        SUM(Order_Count) AS City_Order_Count
    FROM 
        RevenueCTE 
    INNER JOIN 
        customer c ON c.c_customer_sk = ws_bill_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_city
),
HighPerformingCities AS (
    SELECT 
        ca_city,
        City_Total_Sales,
        City_Order_Count,
        DENSE_RANK() OVER (ORDER BY City_Total_Sales DESC) AS Sales_Rank
    FROM 
        SalesSummary
    WHERE 
        City_Total_Sales > (SELECT AVG(City_Total_Sales) FROM SalesSummary)
)
SELECT 
    ca.city,
    COALESCE(CAST(AVG(cd_purchase_estimate) AS DECIMAL(10,2)), 0) AS Avg_Purchase_Estimate,
    COALESCE(MAX(cd_credit_rating), 'Unknown') AS Top_Credit_Rating,
    CASE 
        WHEN Sales_Rank <= 5 THEN 'Top City'
        ELSE 'Other'
    END AS City_Category
FROM 
    HighPerformingCities hp
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = hp.ws_bill_customer_sk LIMIT 1)
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = hp.ws_bill_customer_sk LIMIT 1)
GROUP BY 
    ca.city, Sales_Rank
ORDER BY 
    Avg_Purchase_Estimate DESC;
