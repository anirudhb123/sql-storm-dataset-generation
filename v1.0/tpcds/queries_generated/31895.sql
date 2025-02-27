
WITH recursive cte_sales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM catalog_sales
    GROUP BY cs_item_sk
),
cte_customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
cte_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ci.total_inventory, 0) AS total_inventory,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status
FROM item i
LEFT JOIN cte_sales ss ON i.i_item_sk = ss.cs_item_sk
LEFT JOIN cte_inventory ci ON i.i_item_sk = ci.inv_item_sk
INNER JOIN cte_customer_details cd ON cd.c_customer_sk IN (
    SELECT DISTINCT CASE WHEN cd.rank <= 5 THEN c.c_customer_sk END
    FROM cte_customer_details cd
    WHERE cd.rank <= 5
)
WHERE (COALESCE(ss.total_sales, 0) > 1000 AND ci.total_inventory < 50) 
   OR (cd.cd_marital_status = 'M' AND cd.cd_purchase_estimate > 5000)
ORDER BY total_sales DESC, total_inventory ASC
LIMIT 100;
