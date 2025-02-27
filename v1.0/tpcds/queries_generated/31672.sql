
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
), 
High_Profit_Items AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_profit) > 1000
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE 
        WHEN SUM(ws.ws_net_profit) IS NULL THEN 'No Profit'
        ELSE CONCAT('Total Profit: $', CAST(SUM(ws.ws_net_profit) AS VARCHAR))
    END AS profit_statement
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    High_Profit_Items hpi ON ws.ws_item_sk = hpi.ws_item_sk
WHERE 
    ws.ws_ship_date_sk IS NOT NULL
    AND (c.c_birth_year < (YEAR(CURRENT_DATE) - 18) OR c.c_birth_country IS NULL)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city
HAVING 
    total_quantity_sold > 5
ORDER BY 
    total_profit DESC
LIMIT 10;

SELECT 
    'Total Records' AS label, COUNT(*) AS count
FROM 
    store_sales
UNION ALL
SELECT 
    'Unique Customers' AS label, COUNT(DISTINCT ss_customer_sk) AS count
FROM 
    store_sales;
