
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        1 AS level
    FROM store
    WHERE s_state = 'CA' AND s_rec_start_date <= CURRENT_DATE

    UNION ALL

    SELECT 
        s.store_sk,
        s.s_store_name,
        s.s_number_employees,
        s.s_floor_space,
        sh.level + 1
    FROM sales_hierarchy sh
    JOIN store s ON s.s_manager = sh.s_store_name
    WHERE s.s_rec_start_date <= CURRENT_DATE
),

total_sales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_net_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                            AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ss_store_sk
),

combined AS (
    SELECT 
        h.s_store_name,
        h.s_number_employees,
        h.s_floor_space,
        ts.total_net_sales,
        ts.total_transactions
    FROM sales_hierarchy h
    LEFT JOIN total_sales ts ON h.s_store_sk = ts.ss_store_sk
)

SELECT 
    c.ca_state,
    AVG(COALESCE(c.total_net_sales, 0)) AS avg_net_sales,
    SUM(c.total_transactions) AS total_transactions,
    COUNT(DISTINCT c.s_store_name) AS store_count
FROM combined c
JOIN customer_address ca ON c.s_store_sk = ca.ca_address_sk
WHERE c.total_net_sales IS NOT NULL
GROUP BY c.ca_state
HAVING avg_net_sales > (SELECT AVG(total_net_sales) FROM total_sales)
ORDER BY avg_net_sales DESC;

