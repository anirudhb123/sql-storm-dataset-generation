
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_cdemo_sk,
        1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
item_with_returns AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        COALESCE(is.total_sales, 0) AS total_sales,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM item item
    LEFT JOIN item_sales is ON item.i_item_sk = is.ws_item_sk
    LEFT JOIN catalog_returns cr ON item.i_item_sk = cr.cr_item_sk
    GROUP BY item.i_item_sk, item.i_item_id
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ih.total_sales,
        ih.total_returns,
        ih.return_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY ih.total_sales DESC) AS customer_rank
    FROM customer c
    JOIN item_with_returns ih ON c.c_customer_sk = ih.total_sales
),
sales_summary AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(SUM(cs.total_sales), 0) AS total_sales_sum,
        COUNT(DISTINCT cs.total_returns) AS total_return_customers,
        COUNT(DISTINCT cs.return_count) AS total_returned_items
    FROM customer_hierarchy ch
    LEFT JOIN customer_sales cs ON ch.c_customer_sk = cs.c_customer_sk
    GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name
)
SELECT 
    s.customer_sk,
    s.customer_first_name,
    s.customer_last_name,
    s.total_sales_sum,
    s.total_return_customers,
    s.total_returned_items,
    (s.total_sales_sum / NULLIF(s.total_returned_items, 0)) AS avg_sales_per_return
FROM sales_summary s
WHERE s.total_return_customers > 0
ORDER BY avg_sales_per_return DESC;
