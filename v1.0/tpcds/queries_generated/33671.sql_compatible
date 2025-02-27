
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit) OVER (PARTITION BY c.c_customer_sk), 0.00) AS total_profit,
        1 AS level
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit) + sh.total_profit, sh.total_profit) AS total_profit,
        sh.level + 1
    FROM customer c
    JOIN SalesHierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE sh.level < 10
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, sh.total_profit, sh.level
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_profit,
    d.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    AVG(ss.ss_net_profit) AS avg_store_profit,
    CASE 
        WHEN s.total_profit > (SELECT AVG(total_profit) FROM SalesHierarchy) THEN 'Above Average'
        ELSE 'Below Average'
    END AS profit_category
FROM SalesHierarchy s
LEFT JOIN web_sales ws ON s.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN store_sales ss ON s.c_customer_sk = ss.ss_customer_sk
LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2023
GROUP BY s.c_first_name, s.c_last_name, s.total_profit, d.d_year
HAVING COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY s.total_profit DESC, s.c_last_name;
