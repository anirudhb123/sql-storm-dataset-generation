
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY ss_store_sk
    
    UNION ALL
    
    SELECT 
        s.s_store_sk,
        sh.total_sales,
        sh.total_transactions,
        sh.level + 1
    FROM sales_hierarchy sh
    JOIN store s ON s.s_store_sk = sh.ss_store_sk
    WHERE sh.level < 5
)
SELECT 
    ca_state,
    SUM( CASE 
            WHEN ss.net_paid > 100 THEN ss.net_paid 
            ELSE 0 
        END ) AS high_value_sales,
    AVG(ss.ss_net_profit) AS average_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
    COALESCE(ROUND(SUM(ss.ss_net_paid_inc_tax) / NULLIF(COUNT(ss.ss_ticket_number), 0), 2), 0) AS avg_net_paid
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN sales_hierarchy sh ON sh.ss_store_sk = ss.ss_store_sk
WHERE 
    ss.ss_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '30 days') 
    AND (c.c_preferred_cust_flag = 'Y' OR (c.c_birth_month = EXTRACT(MONTH FROM CURRENT_DATE) AND c.c_birth_day = EXTRACT(DAY FROM CURRENT_DATE)))
GROUP BY 
    ca_state
HAVING 
    SUM(ss.ss_ext_sales_price) > 1000
ORDER BY 
    high_value_sales DESC
LIMIT 10;
