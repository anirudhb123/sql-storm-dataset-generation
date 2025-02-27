
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        0 AS level
    FROM 
        customer
    WHERE 
        c_customer_sk IN (SELECT sr_customer_sk FROM store_returns)
    
    UNION ALL
    
    SELECT 
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales s ON sh.c_customer_sk = s.ss_customer_sk
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
)
, recent_sales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.level,
    COALESCE(rs.total_profit, 0) AS total_profit
FROM 
    sales_hierarchy sh
LEFT OUTER JOIN 
    recent_sales rs ON sh.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    sh.level < 3
ORDER BY 
    total_profit DESC, sh.c_last_name, sh.c_first_name
LIMIT 100;
