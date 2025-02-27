
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        sh.level + 1
    FROM store_sales s
    JOIN sales_hierarchy sh ON s.ss_customer_sk = sh.c_customer_sk
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
)

SELECT 
    sh.c_first_name,
    sh.c_last_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    COALESCE(SUM(ss.ss_net_profit), 0) AS total_net_profit,
    AVG(ss.ss_net_paid) AS avg_net_paid,
    SUM(ss.ss_sales_price * ss.ss_quantity) AS total_sales_value,
    DENSE_RANK() OVER (PARTITION BY sh.level ORDER BY SUM(ss.ss_sales_price * ss.ss_quantity) DESC) AS sales_rank
FROM sales_hierarchy sh
LEFT JOIN store_sales ss ON sh.c_customer_sk = ss.ss_customer_sk
GROUP BY sh.c_first_name, sh.c_last_name, sh.level
HAVING COUNT(DISTINCT ss.ss_ticket_number) > 5
ORDER BY sh.level, total_net_profit DESC;

SELECT 
    wp.wp_web_page_id,
    SUM(ws.ws_net_profit) AS total_web_sales_profit,
    COUNT(ws.ws_order_number) AS total_orders,
    MAX(ws.ws_sales_price) AS max_sales_price
FROM web_page wp
JOIN web_sales ws ON wp.wp_web_page_sk = ws.ws_web_page_sk
WHERE wp.wp_creation_date_sk >= (
    SELECT MAX(d.d_date_sk)
    FROM date_dim d
    WHERE d.d_year = 2023 AND d.d_month_seq = 12
) AND ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
GROUP BY wp.wp_web_page_id
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY total_web_sales_profit DESC
LIMIT 10;
