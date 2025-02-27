
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_name, 1 AS level, NULL AS parent_id
    FROM store
    WHERE s_closed_date_sk IS NULL
    UNION ALL
    SELECT s.s_store_sk, s.s_store_name, sh.level + 1, sh.s_store_sk
    FROM store s
    JOIN sales_hierarchy sh ON sh.s_store_sk = s.s_store_sk
),
inventory_summary AS (
    SELECT 
        i.inv_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM inventory i
    WHERE i.inv_date_sk = (
        SELECT MAX(inv_date_sk) FROM inventory
    )
    GROUP BY i.inv_warehouse_sk
),
customer_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_quantity,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
sales_summary AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        MAX(ss.ss_sales_price) AS max_price,
        MIN(ss.ss_sales_price) AS min_price
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
),
final_report AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned,
        COALESCE(cr.return_count, 0) AS return_count,
        ss.total_sales,
        ss.total_quantity,
        ss.max_price,
        ss.min_price,
        i.total_quantity AS inventory_quantity,
        sh.level AS store_level
    FROM customer c
    LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN sales_summary ss ON ss.ss_sold_date_sk = (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ss.ss_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 50)
    LEFT JOIN inventory_summary i ON i.inv_warehouse_sk = (
        SELECT w_warehouse_sk FROM warehouse WHERE w_warehouse_name = 'Main Warehouse')
    LEFT JOIN sales_hierarchy sh ON sh.s_store_sk = (
        SELECT s_store_sk FROM store WHERE s_store_name = 'Central Store')
)
SELECT 
    f.c_customer_sk,
    f.total_returned,
    f.return_count,
    f.total_sales,
    f.total_quantity,
    f.max_price,
    f.min_price,
    f.inventory_quantity,
    f.store_level
FROM final_report f
WHERE (f.total_sales > 1000 OR f.total_returned > 5)
ORDER BY f.total_sales DESC, f.return_count ASC
LIMIT 100;
