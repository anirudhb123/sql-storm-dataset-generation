
WITH RECURSIVE popular_items AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, 0 AS purchase_count
    FROM item
    WHERE i_item_sk IN (
        SELECT sr_item_sk
        FROM store_returns
        GROUP BY sr_item_sk
        HAVING SUM(sr_return_quantity) > 10
    )
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, p.purchase_count + 1
    FROM item i
    JOIN popular_items p ON i.i_item_sk = p.i_item_sk
    WHERE i.i_item_id <> p.i_item_id
),
sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
),
items_with_sales AS (
    SELECT 
        pi.i_item_sk,
        pi.i_item_id,
        pi.i_item_desc,
        pi.i_current_price,
        sd.total_sales,
        sd.total_orders,
        ROW_NUMBER() OVER (PARTITION BY pi.i_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM popular_items pi
    LEFT JOIN sales_data sd ON pi.i_item_sk = sd.ws_item_sk
)
SELECT 
    iws.i_item_id,
    iws.i_item_desc,
    COALESCE(iws.total_sales, 0) AS total_sales,
    COALESCE(iws.total_orders, 0) AS total_orders,
    CASE 
        WHEN iws.total_sales IS NULL THEN 'No sales recorded'
        ELSE 'Sales recorded'
    END AS sales_status
FROM items_with_sales iws
WHERE iws.sales_rank = 1
ORDER BY total_sales DESC
LIMIT 10;
