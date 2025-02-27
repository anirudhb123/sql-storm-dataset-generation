
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, c_birth_year, 
           0 AS level
    FROM customer
    WHERE c_birth_year >= 1990
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, c.c_birth_year,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesSummary AS (
    SELECT ws_ship_date_sk, ws_item_sk, SUM(ws_quantity) AS total_quantity, 
           SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
),
WarehouseInventory AS (
    SELECT inv.inventory_date, inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inventory_date, inv.inv_item_sk
),
CombinedData AS (
    SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.c_birth_year,
           COALESCE(ss.total_quantity, 0) AS total_quantity,
           COALESCE(ss.total_sales, 0) AS total_sales,
           wi.total_inventory, 'Customer Sales Data' AS data_type
    FROM CustomerHierarchy cs
    LEFT JOIN SalesSummary ss ON cs.c_customer_sk = ss.ws_item_sk
    LEFT JOIN WarehouseInventory wi ON ss.ws_item_sk = wi.inv_item_sk
)
SELECT *,
       CASE 
           WHEN total_sales > 1000 THEN 'High Roller'
           WHEN total_sales BETWEEN 500 AND 1000 THEN 'Regular'
           ELSE 'Low spender' 
       END AS spending_category,
       ROW_NUMBER() OVER (PARTITION BY spending_category ORDER BY total_sales DESC) AS rank
FROM CombinedData
WHERE total_inventory IS NOT NULL
ORDER BY total_sales DESC;
