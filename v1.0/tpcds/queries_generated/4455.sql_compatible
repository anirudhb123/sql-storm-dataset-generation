
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
customer_count AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS customer_order_count
    FROM web_sales
    INNER JOIN customer ON ws_bill_customer_sk = c_customer_sk
    WHERE c_birth_year >= 1970
    GROUP BY c_customer_sk
),
inventory_status AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        cs.customer_order_count,
        is.total_on_hand,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM sales_data sd
    LEFT JOIN customer_count cs ON sd.ws_item_sk = cs.c_customer_sk
    LEFT JOIN inventory_status is ON sd.ws_item_sk = is.inv_item_sk
)
SELECT 
    r.ws_item_sk,
    r.total_quantity,
    r.total_sales,
    r.order_count,
    r.customer_order_count,
    r.total_on_hand,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Selling Item'
        WHEN r.total_on_hand IS NULL THEN 'Out of Stock'
        ELSE 'Regular Item'
    END AS item_status
FROM ranked_sales r
WHERE r.total_quantity > 100
  AND (r.customer_order_count IS NULL OR r.customer_order_count > 5)
ORDER BY r.total_sales DESC;
