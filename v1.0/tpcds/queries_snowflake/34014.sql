
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        NULL AS parent_id,
        0 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        sh.c_customer_sk AS parent_id,
        sh.level + 1 AS level
    FROM customer c
    JOIN sales_hierarchy sh ON sh.c_customer_sk = c.c_current_cdemo_sk
),
sales_summary AS (
    SELECT 
        s.ss_store_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid_inc_tax) AS total_net_paid,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY s.ss_store_sk ORDER BY SUM(s.ss_quantity) DESC) AS sales_rank
    FROM store_sales s
    GROUP BY s.ss_store_sk
),
customer_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        AVG(sr_return_amt_inc_tax) AS avg_return_value
    FROM store_returns
    GROUP BY sr_customer_sk
),
final_output AS (
    SELECT 
        sh.c_first_name,
        sh.c_last_name,
        ca.ca_city,
        ss.total_quantity,
        ss.total_net_paid,
        cr.total_returns,
        cr.avg_return_value,
        CASE 
            WHEN cr.total_returns IS NULL THEN 'No Returns'
            WHEN cr.total_returns > 0 THEN 'Has Returns'
            ELSE 'Unknown'
        END AS return_status
    FROM sales_hierarchy sh
    LEFT JOIN customer_address ca ON sh.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN sales_summary ss ON sh.c_customer_sk = ss.ss_store_sk
    LEFT JOIN customer_returns cr ON sh.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.ca_city,
    COALESCE(f.total_quantity, 0) AS total_quantity,
    COALESCE(f.total_net_paid, 0) AS total_net_paid,
    COALESCE(f.total_returns, 0) AS total_returns,
    COALESCE(f.avg_return_value, 0) AS avg_return_value,
    f.return_status
FROM final_output f
WHERE COALESCE(f.total_net_paid, 0) > 1000 
AND f.return_status = 'Has Returns'
ORDER BY f.total_net_paid DESC;
