
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 2000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_net_profit) > 1000
    
    UNION ALL

    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_net_profit) + COALESCE(SUM(sh.total_profit), 0) AS total_profit,
           COUNT(ws.ws_order_number) + COALESCE(SUM(sh.order_count), 0) AS order_count
    FROM SalesHierarchy sh
    JOIN customer c ON c.c_current_cdemo_sk = sh.c_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)

SELECT sh.c_first_name,
       sh.c_last_name,
       sh.total_profit,
       sh.order_count,
       CASE
           WHEN sh.total_profit > 5000 THEN 'High Profit'
           WHEN sh.total_profit BETWEEN 1001 AND 5000 THEN 'Medium Profit'
           ELSE 'Low Profit'
       END AS profit_category,
       COALESCE((
           SELECT STRING_AGG(CONCAT(wp.wp_web_page_id, ': ', wp.wp_creation_date_sk))
           FROM web_page wp
           WHERE wp.wp_customer_sk = sh.c_customer_sk
       ), 'No pages') AS related_web_pages
FROM SalesHierarchy sh
WHERE sh.order_count > 5
ORDER BY sh.total_profit DESC
LIMIT 10;
