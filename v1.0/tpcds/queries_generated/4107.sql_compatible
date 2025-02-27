
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
HighProfitItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_net_profit
    FROM 
        item
    JOIN 
        RankedSales sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        sales.total_net_profit > (SELECT AVG(total_net_profit) FROM RankedSales)
) 
SELECT 
    COALESCE(ca.ca_city, 'N/A') AS city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(hp.total_quantity) AS total_sales_quantity,
    AVG(hp.total_net_profit) AS avg_net_profit
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    HighProfitItems hp ON hp.i_item_id IN (
        SELECT ws.ws_item_sk
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = c.c_customer_sk
    )
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY 
    avg_net_profit DESC
LIMIT 10;
