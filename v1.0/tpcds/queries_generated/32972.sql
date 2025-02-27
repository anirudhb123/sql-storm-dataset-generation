
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_birth_year, c.c_current_addr_sk, 
           cd.cd_income_band_sk, cd.cd_gender,
           0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year > 1980
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_birth_year, c.c_current_addr_sk, 
           cd.cd_income_band_sk, cd.cd_gender,
           ch.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk
    WHERE ch.level < 5
),
StoreInventory AS (
    SELECT inv.inv_warehouse_sk, inv.inv_item_sk, 
           SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk, inv.inv_item_sk
),
SalesSummary AS (
    SELECT ws.ws_ship_date_sk, 
           SUM(ws.ws_sales_price) AS total_sales, 
           SUM(ws.ws_quantity) AS total_units
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_ship_date_sk
),
ReturnSummary AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    ch.c_customer_sk, 
    ch.c_first_name || ' ' || ch.c_last_name AS full_name,
    ch.cd_gender,
    ch.cd_income_band_sk,
    coalesce(si.total_quantity, 0) AS warehouse_quantity,
    coalesce(ss.total_sales, 0) AS total_sales,
    rs.total_returns,
    CASE 
        WHEN coalesce(ss.total_sales, 0) > 10000 THEN 'High Performer'
        WHEN coalesce(ss.total_sales, 0) BETWEEN 5000 AND 10000 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM CustomerHierarchy ch
LEFT JOIN StoreInventory si ON ch.c_current_addr_sk = si.inv_warehouse_sk
LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.ws_ship_date_sk
LEFT JOIN ReturnSummary rs ON ch.c_customer_sk = rs.sr_item_sk
WHERE (ch.cd_gender = 'F' OR si.total_quantity IS NULL)
  AND (EXISTS (SELECT 1 FROM warehouse w WHERE w.w_warehouse_sk = si.inv_warehouse_sk AND w.w_country = 'USA'))
  AND (ch.c_birth_year BETWEEN 1985 AND 1995 OR ch.cd_income_band_sk IS NULL)
ORDER BY ch.c_customer_sk, full_name;
