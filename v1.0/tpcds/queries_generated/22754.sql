
WITH RECURSIVE customer_analysis AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           COALESCE(cd.cd_dep_count, 0) AS dependent_count,
           COALESCE(cd.cd_dep_employed_count, 0) AS employed_dependent_count,
           COALESCE(cd.cd_dep_college_count, 0) AS college_dependent_count,
           CASE 
               WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
               WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS customer_value_category,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
      AND cd.cd_marital_status IS NOT NULL
),
item_sales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
item_inventory AS (
    SELECT inv.inv_item_sk,
           SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
sales_overview AS (
    SELECT ia.c_customer_id,
           sa.total_sales,
           ia.total_inventory,
           CASE 
               WHEN sa.total_sales IS NULL THEN 0
               ELSE ia.total_inventory / sa.total_sales
           END AS inventory_to_sales_ratio
    FROM item_sales sa
    FULL OUTER JOIN item_inventory ia ON sa.ws_item_sk = ia.inv_item_sk
)
SELECT ca.c_customer_id,
       ca.customer_value_category,
       so.total_sales,
       so.total_inventory,
       so.inventory_to_sales_ratio,
       RANK() OVER (PARTITION BY ca.customer_value_category ORDER BY so.inventory_to_sales_ratio DESC) AS ratio_rank
FROM customer_analysis ca
LEFT JOIN sales_overview so ON ca.c_customer_id = so.c_customer_id
WHERE (so.inventory_to_sales_ratio IS NOT NULL OR ca.dependent_count > 2)
      AND (so.total_sales > 500 OR ca.customer_value_category = 'High Value')
ORDER BY ca.customer_value_category, ratio_rank;
