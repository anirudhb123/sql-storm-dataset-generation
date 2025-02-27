
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_sales,
        1 AS level
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.total_sales + COALESCE(SUM(ss.ss_net_paid), 0) AS total_sales,
        sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_current_hdemo_sk = sh.c_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, sh.total_sales, sh.level
)
SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    sh.total_sales,
    RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
FROM sales_hierarchy sh
WHERE sh.total_sales > (
    SELECT AVG(total_sales) FROM sales_hierarchy
)
ORDER BY sales_rank
LIMIT 100;

-- Additional Sales Analysis
SELECT 
    s.s_store_name,
    SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COUNT(ws.ws_item_sk) AS total_items
FROM store s
JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
WHERE ws.ws_ship_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_year = 2023)
GROUP BY s.s_store_name
HAVING total_net_paid > (
    SELECT AVG(total_net_paid) FROM (
        SELECT SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
        FROM web_sales ws
        GROUP BY ws.ws_warehouse_sk
    ) AS avg_sales
)
ORDER BY total_net_paid DESC
LIMIT 50;

-- Customer Returns Summary
SELECT 
    ca.ca_state,
    COUNT(cr.cr_return_amount) AS total_returns,
    SUM(cr.cr_return_amount) AS total_returned_amount,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS unique_customers
FROM catalog_returns cr
JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
WHERE cr.cr_returned_date_sk IN (
    SELECT d.d_date_sk 
    FROM date_dim d 
    WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
)
GROUP BY ca.ca_state
HAVING total_returned_amount > 10000
ORDER BY total_returned_amount DESC;
