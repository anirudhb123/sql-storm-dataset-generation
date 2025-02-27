
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS FullName,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS TotalSales,
        SUM(ws.ws_net_profit) AS NetProfit,
        COUNT(ws.ws_item_sk) AS ItemCount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
MergedInfo AS (
    SELECT 
        ci.FullName,
        ci.ca_city,
        ci.ca_state,
        si.TotalSales,
        si.NetProfit,
        si.ItemCount
    FROM 
        CustomerInfo ci
    JOIN 
        SalesInfo si ON ci.c_customer_id = (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_order_number = si.ws_order_number LIMIT 1)
)
SELECT 
    FullName, 
    ca_city, 
    ca_state, 
    TotalSales,
    NetProfit,
    ItemCount,
    CASE 
        WHEN TotalSales > 1000 THEN 'High Value'
        WHEN TotalSales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS CustomerValueCategory
FROM 
    MergedInfo
WHERE 
    ca_state IN ('CA', 'NY')
ORDER BY 
    NetProfit DESC, TotalSales DESC;
