
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, 
           s_store_name, 
           s_number_employees, 
           s_floor_space, 
           s_market_id,
           1 AS level
    FROM store
    WHERE s_closed_date_sk IS NULL
    UNION ALL
    SELECT s_store_sk, 
           s_store_name, 
           s_number_employees, 
           s_floor_space, 
           s_market_id,
           sh.level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s_market_id = sh.s_market_id
    WHERE s_closed_date_sk IS NULL
), summarized_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit,
        MAX(ws.ws_sales_price) AS max_price
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND 20000
    GROUP BY ws.web_site_id
), ranked_sales AS (
    SELECT 
        web_id,
        total_sales,
        total_orders,
        average_profit,
        max_price,
        ROW_NUMBER() OVER (PARTITION BY web_id ORDER BY total_sales DESC) AS rank
    FROM summarized_sales
), customer_purchase_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ws.ws_net_paid_inc_tax) > 500
)
SELECT 
    sh.s_store_name, 
    sh.s_number_employees, 
    sh.s_floor_space, 
    r.total_sales,
    r.average_profit,
    c.c_customer_id,
    c.cd_gender,
    COUNT(c.c_customer_id) AS customer_count,
    SUM(CASE WHEN c.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
FROM sales_hierarchy sh
LEFT JOIN ranked_sales r ON r.web_id IN (SELECT web_site_id FROM summarized_sales WHERE max_price > 100)
LEFT JOIN customer_purchase_summary c ON c.total_spent > 1000
GROUP BY sh.s_store_name, sh.s_number_employees, sh.s_floor_space, r.total_sales, r.average_profit, c.c_customer_id, c.cd_gender
ORDER BY total_sales DESC, married_count DESC
LIMIT 10;
