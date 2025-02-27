
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(cs_order_number) AS total_orders,
        1 AS level
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
    UNION ALL
    SELECT 
        s.ss_customer_sk,
        SUM(s.ss_net_profit) + sh.total_profit AS total_profit,
        COUNT(s.ss_ticket_number) + sh.total_orders AS total_orders,
        sh.level + 1
    FROM store_sales s
    JOIN sales_hierarchy sh ON s.ss_customer_sk = sh.customer_sk
    GROUP BY s.ss_customer_sk, sh.total_profit, sh.total_orders, sh.level
),
address_count AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk
),
date_range AS (
    SELECT 
        MIN(d.d_date) AS min_date,
        MAX(d.d_date) AS max_date
    FROM date_dim d
    WHERE d.d_year BETWEEN 2020 AND 2023
),
web_sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk BETWEEN dr.min_date AND dr.max_date
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk,
    COALESCE(sh.total_profit, 0) AS total_catalog_profit,
    COALESCE(ws.total_web_profit, 0) AS total_web_profit,
    addr.address_count,
    sh.total_orders + ws.web_orders AS total_combined_orders,
    CASE 
        WHEN COALESCE(sh.total_profit, 0) > 5000 THEN 'High Value'
        WHEN COALESCE(sh.total_profit, 0) BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM customer c
LEFT JOIN sales_hierarchy sh ON c.c_customer_sk = sh.customer_sk
LEFT JOIN web_sales_summary ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN address_count addr ON c.c_customer_sk = addr.c_customer_sk
WHERE (addr.address_count IS NULL OR addr.address_count > 1)
ORDER BY total_combined_orders DESC, customer_value_category, c.c_customer_sk
LIMIT 100;
