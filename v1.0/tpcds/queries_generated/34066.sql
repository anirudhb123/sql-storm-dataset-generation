
WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
    HAVING 
        total_profit > 1000
    UNION ALL 
    SELECT 
        s.s_store_sk AS c_customer_sk, 
        s.s_store_id AS c_customer_id, 
        SUM(cs.cs_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM 
        store s 
    JOIN 
        catalog_sales cs ON s.s_store_sk = cs.cs_ship_customer_sk
    WHERE 
        cs.cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND cs.cs_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s.s_store_sk, s.s_store_id
    HAVING 
        total_profit > 1000
)
SELECT 
    customer.c_customer_id, 
    COALESCE(sales.total_profit, 0) AS total_profit,
    COALESCE(store.total_profit, 0) AS store_profit,
    (COALESCE(sales.total_profit, 0) + COALESCE(store.total_profit, 0)) AS combined_profit,
    CASE 
        WHEN COALESCE(sales.total_profit, 0) > COALESCE(store.total_profit, 0) THEN 'Customer'
        ELSE 'Store'
    END AS source_of_profit
FROM 
    (SELECT DISTINCT c_customer_id FROM customer) customer
LEFT JOIN 
    (SELECT c_customer_id, total_profit FROM SalesCTE WHERE profit_rank = 1) sales 
ON 
    customer.c_customer_id = sales.c_customer_id
FULL OUTER JOIN 
    (SELECT s_store_id, total_profit FROM SalesCTE WHERE profit_rank = 1) store 
ON 
    customer.c_customer_id = store.s_store_id
WHERE 
    (combined_profit IS NOT NULL)
ORDER BY 
    combined_profit DESC
LIMIT 100;
