
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        sh.total_profit + COALESCE(SUM(ws.ws_net_profit), 0),
        sh.order_count + COALESCE(COUNT(ws.ws_order_number), 0),
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY (sh.total_profit + COALESCE(SUM(ws.ws_net_profit), 0)) DESC) AS rnk
    FROM 
        SalesHierarchy sh
    JOIN 
        customer c ON c.c_customer_sk = sh.c_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, sh.total_profit, sh.order_count
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    sh.total_profit,
    sh.order_count,
    CASE 
        WHEN sh.total_profit IS NULL THEN 'No Sales'
        WHEN sh.total_profit > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value,
    CONCAT(c.c_first_name, ' ', c.c_last_name, ' has a total of $', 
        COALESCE(CAST(sh.total_profit AS VARCHAR), '0'), 
        ' with ', COALESCE(CAST(sh.order_count AS VARCHAR), '0'), ' orders.') AS customer_summary
FROM 
    SalesHierarchy sh
JOIN 
    customer c ON sh.c_customer_sk = c.c_customer_sk
WHERE 
    sh.rnk = 1
ORDER BY 
    sh.total_profit DESC
LIMIT 10;
