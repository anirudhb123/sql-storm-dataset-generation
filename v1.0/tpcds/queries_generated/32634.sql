
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_salutation, c_birth_year, 0 AS level
    FROM customer
    WHERE c_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_birth_year IS NOT NULL)
    
    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_salutation, ch.c_birth_year, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
    WHERE ch.level < 5
),
order_totals AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458849 AND 2458925 -- Example range
    GROUP BY ws_bill_customer_sk
),
returns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
sales_summary AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(ot.total_sales, 0) AS total_sales,
        COALESCE(rt.total_returned, 0) AS total_returned,
        (COALESCE(ot.total_sales, 0) - COALESCE(rt.total_returned, 0)) AS net_sales,
        ot.order_count
    FROM customer_hierarchy ch
    LEFT JOIN order_totals ot ON ch.c_customer_sk = ot.customer_sk
    LEFT JOIN returns rt ON ch.c_customer_sk = rt.sr_customer_sk
),
ranked_sales AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY net_sales DESC) AS sales_rank
    FROM sales_summary
)
SELECT 
    c_first_name,
    c_last_name,
    total_sales,
    total_returned,
    net_sales,
    order_count,
    sales_rank
FROM ranked_sales
WHERE sales_rank <= 10
ORDER BY net_sales DESC;
