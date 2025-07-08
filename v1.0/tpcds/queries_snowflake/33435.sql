
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 0 AS level
    FROM customer c
    WHERE c.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_info AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
),
inventory_info AS (
    SELECT 
        inv.inv_item_sk,
        MAX(inv.inv_quantity_on_hand) AS max_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
combined_info AS (
    SELECT
        si.ws_item_sk,
        si.total_quantity_sold,
        si.total_sales,
        ii.max_quantity_on_hand
    FROM sales_info si
    LEFT JOIN inventory_info ii ON si.ws_item_sk = ii.inv_item_sk
),
final_report AS (
    SELECT
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ci.total_quantity_sold,
        ci.total_sales,
        ci.max_quantity_on_hand,
        CASE 
            WHEN ci.total_sales IS NULL THEN 'No Sales'
            WHEN ci.total_sales < 1000 THEN 'Low Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM customer_hierarchy ch
    LEFT JOIN combined_info ci ON ch.c_customer_sk = ci.ws_item_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.total_quantity_sold,
    fr.total_sales,
    fr.max_quantity_on_hand,
    fr.sales_category
FROM final_report fr
ORDER BY sales_category ASC, fr.total_sales DESC;
