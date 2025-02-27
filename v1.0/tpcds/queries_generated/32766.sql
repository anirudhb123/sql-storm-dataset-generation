
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss.s_store_sk,
        ss.s_sold_date_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ss.s_store_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS rnk
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ss.s_store_sk, ss.s_sold_date_sk
), customer_rank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    s.store_id,
    ss.total_sales,
    ss.total_orders,
    cr.c_first_name,
    cr.c_last_name,
    ai.city,
    ai.state,
    ai.customer_count,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        ELSE CAST(ss.total_sales AS VARCHAR)
    END AS sales_statement
FROM sales_summary ss
JOIN store s ON ss.s_store_sk = s.s_store_sk
LEFT JOIN customer_rank cr ON cr.purchase_rank <= 10
LEFT JOIN address_info ai ON ai.customer_count > 0
WHERE ss.total_orders > 5
ORDER BY ss.total_sales DESC, cr.purchase_rank;
