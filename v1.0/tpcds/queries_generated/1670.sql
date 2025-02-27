
WITH CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count,
        MIN(ca.ca_city) AS first_city,
        MAX(ca.ca_state) AS last_state
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
MarketTrends AS (
    SELECT 
        s_item_sk,
        AVG(total_net_profit) OVER (PARTITION BY s_item_sk ORDER BY ws_sold_date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_profit_last_week,
        SUM(total_quantity) AS total_quantity_for_item
    FROM 
        SalesData
    GROUP BY 
        s_item_sk, ws_sold_date_sk
)
SELECT 
    c.c_customer_id,
    ca.address_count,
    ca.first_city,
    mt.avg_profit_last_week,
    mt.total_quantity_for_item
FROM 
    CustomerAddresses ca
JOIN 
    customer c ON ca.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    MarketTrends mt ON mt.total_quantity_for_item > 100
WHERE 
    c.c_birth_month = 12
    AND (mt.avg_profit_last_week IS NULL OR mt.avg_profit_last_week > 0)
ORDER BY 
    ca.address_count DESC, mt.total_quantity_for_item ASC
LIMIT 50;
