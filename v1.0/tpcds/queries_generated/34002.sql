
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        CAST(ss_sales_price AS DECIMAL(10, 2)) AS sales_price,
        1 AS level
    FROM 
        store 
        JOIN store_sales ON store.s_store_sk = store_sales.ss_store_sk
    WHERE 
        ss_sales_price IS NOT NULL

    UNION ALL

    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.s_number_employees,
        sh.s_floor_space,
        CAST(ss.sales_price * 1.1 AS DECIMAL(10, 2)),
        level + 1
    FROM 
        sales_hierarchy sh
        JOIN store_sales ss ON sh.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.sales_price IS NOT NULL
        AND level < 5
)

SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS profit_rank,
    STRING_AGG(DISTINCT ca_state, ', ') AS states_contributed
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    sales_hierarchy sh ON sh.s_store_sk = ws.ws_warehouse_sk
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
HAVING 
    total_net_profit > 0 AND 
    EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_number_employees > 5 AND s.s_store_sk = sh.s_store_sk
    )
ORDER BY 
    total_net_profit DESC
LIMIT 10;
