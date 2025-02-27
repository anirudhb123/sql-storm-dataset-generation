
WITH RECURSIVE SalesHierarchy AS (
    SELECT s_sales.s_sold_date_sk, s_sales.ss_item_sk, s_sales.ss_store_sk,
           SUM(ss_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY s_sales.ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS rank
    FROM store_sales s_sales
    JOIN customer c ON s_sales.ss_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY s_sales.s_sold_date_sk, s_sales.ss_item_sk, s_sales.ss_store_sk
),
HighPerformingStores AS (
    SELECT s_store_sk, SUM(total_sales) AS overall_sales
    FROM SalesHierarchy
    WHERE rank <= 5
    GROUP BY s_store_sk
),
TopCustomerDemographics AS (
    SELECT cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 5000
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
StoreInventory AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk, inv_warehouse_sk
)
SELECT s.s_store_name, hc.gender, hc.marital_status, hc.purchase_estimate, 
       COALESCE(hp.overall_sales, 0) AS total_store_sales,
       SUM(si.total_inventory) AS total_inventory_on_hand
FROM HighPerformingStores hp
FULL OUTER JOIN store s ON s.s_store_sk = hp.s_store_sk
JOIN TopCustomerDemographics hc ON hc.customer_count > 0
JOIN StoreInventory si ON si.inv_warehouse_sk = s.s_store_sk
WHERE hc.cd_purchase_estimate IS NOT NULL
GROUP BY s.s_store_name, hc.cd_gender, hc.cd_marital_status, 
         hc.cd_purchase_estimate, hp.overall_sales
HAVING SUM(si.total_inventory) > 100
ORDER BY total_store_sales DESC, hc.purchase_estimate DESC;
