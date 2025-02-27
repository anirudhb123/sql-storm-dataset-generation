
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_month, c_birth_year, 
           c_current_cdemo_sk, 
           (SELECT COUNT(DISTINCT cr_item_sk) 
            FROM catalog_returns 
            WHERE cr_returning_customer_sk = c_customer_sk) AS total_returns
    FROM customer
    WHERE c_birth_year IS NOT NULL AND c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_birth_month, ch.c_birth_year, 
           ch.c_current_cdemo_sk, 
           (SELECT COUNT(DISTINCT cr_item_sk) 
            FROM catalog_returns 
            WHERE cr_returning_customer_sk = ch.c_customer_sk) AS total_returns
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ch.c_customer_sk <> c.c_customer_sk
),
sales_data AS (
    SELECT ws_bill_customer_sk, SUM(ws_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
inventory_status AS (
    SELECT inv_w.warehouse_name, SUM(inv_quantity_on_hand) AS total_inventory,
           CASE 
               WHEN SUM(inv_quantity_on_hand) = 0 THEN 'Out of Stock' 
               WHEN SUM(inv_quantity_on_hand) BETWEEN 1 AND 10 THEN 'Low Stock' 
               ELSE 'In Stock' 
           END AS inventory_status
    FROM inventory inv
    JOIN warehouse inv_w ON inv.inv_warehouse_sk = inv_w.warehouse_sk
    GROUP BY inv_w.warehouse_name
)

SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.c_birth_month,
    ch.c_birth_year,
    COALESCE(sd.total_sales, 0) AS total_sales,
    sd.sales_rank,
    inv.warehouse_name,
    inv.total_inventory,
    inv.inventory_status
FROM customer_hierarchy ch
LEFT JOIN sales_data sd ON ch.c_customer_sk = sd.ws_bill_customer_sk
CROSS JOIN inventory_status inv
WHERE (inv.total_inventory > 20 AND sd.total_sales > 100 
       OR ch.total_returns > 5)
AND (ch.c_birth_month IS NOT NULL OR ch.c_birth_year IS NOT NULL)
ORDER BY ch.c_birth_year DESC, total_sales DESC;
