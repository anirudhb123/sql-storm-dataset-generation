
WITH RECURSIVE SalesHierarchy AS (
    SELECT s_store_sk, s_store_name, s_number_employees, s_floor_space,
           0 AS level
    FROM store
    WHERE s_store_sk = 1
    UNION ALL
    SELECT s.s_store_sk, s.s_store_name, s.s_number_employees, s.s_floor_space,
           sh.level + 1
    FROM store s
    JOIN SalesHierarchy sh ON s.s_division_id = sh.s_store_sk
),
SalesData AS (
    SELECT ss_store_sk, SUM(ss_sales_price) AS total_sales,
           COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ss_store_sk
),
CustomerDemographics AS (
    SELECT cd_gender, COUNT(DISTINCT c_customer_sk) AS customer_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
),
InventorySummary AS (
    SELECT inv_warehouse_sk, SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_warehouse_sk
),
CombinedData AS (
    SELECT sh.s_store_name, sd.total_sales, sd.total_transactions,
           cd.customer_count, cd.avg_purchase_estimate, 
           COALESCE(inv.total_inventory, 0) AS total_inventory
    FROM SalesHierarchy sh
    LEFT JOIN SalesData sd ON sh.s_store_sk = sd.ss_store_sk
    LEFT JOIN CustomerDemographics cd ON 1=1
    LEFT JOIN InventorySummary inv ON sh.s_store_sk = inv.inv_warehouse_sk
)
SELECT s.s_store_name, 
       COALESCE(total_sales, 0) AS total_sales,
       COALESCE(total_transactions, 0) AS total_transactions,
       COALESCE(customer_count, 0) AS customer_count,
       COALESCE(avg_purchase_estimate, 0) AS avg_purchase_estimate,
       total_inventory
FROM CombinedData s
ORDER BY total_sales DESC
LIMIT 10;
