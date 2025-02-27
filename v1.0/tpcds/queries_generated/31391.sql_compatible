
WITH RECURSIVE sales_analysis AS (
    SELECT 
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales 
    GROUP BY 
        ss_item_sk, 
        ss_store_sk
    HAVING 
        SUM(ss_sales_price) > 1000

    UNION ALL

    SELECT 
        ca_address_sk,
        total_sales * 0.1 AS total_sales,
        sales_rank
    FROM 
        customer_address 
    JOIN 
        sales_analysis ON ca_address_sk = sales_rank
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN 
    sales_analysis sa ON ws.ws_item_sk = sa.ss_item_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
    (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND sa.total_sales IS NOT NULL
GROUP BY 
    c.c_first_name, 
    c.c_last_name
HAVING 
    SUM(ws.ws_net_profit) > 50000
ORDER BY 
    profit_rank
LIMIT 10;
