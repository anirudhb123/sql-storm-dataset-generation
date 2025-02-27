
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
inventory_summary AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
),
paired_sales AS (
    SELECT
        ss_item_sk,
        total_sales,
        total_orders,
        COALESCE(is.total_quantity_on_hand, 0) AS stock_balance,
        (total_sales - (COALESCE(is.total_quantity_on_hand, 0) * (SELECT AVG(i_current_price) 
                                                                   FROM item 
                                                                   WHERE i_item_sk = ss_item_sk))) AS profit_margin
    FROM sales_summary s
    LEFT JOIN inventory_summary is ON s.ws_item_sk = is.inv_item_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ps.ss_item_sk,
    ps.total_sales,
    ps.total_orders,
    ps.stock_balance,
    ps.profit_margin
FROM customer_hierarchy ch
JOIN paired_sales ps ON ch.c_current_cdemo_sk = (SELECT cd_demo_sk FROM customer_demographics WHERE cd_demo_sk = ch.c_current_cdemo_sk)
WHERE ps.profit_margin > 0
ORDER BY ps.total_sales DESC, ch.c_last_name ASC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
