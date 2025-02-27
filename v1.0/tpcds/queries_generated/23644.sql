
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS row_num
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
catalog_data AS (
    SELECT 
        cs.cs_item_sk, 
        SUM(cs.cs_quantity) AS total_quantity_catalog,
        SUM(cs.cs_net_paid) AS total_sales_catalog
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        COALESCE(sd.total_quantity, 0) AS total_web_quantity,
        COALESCE(cd.total_quantity_catalog, 0) AS total_catalog_quantity,
        (COALESCE(sd.total_sales, 0) + COALESCE(cd.total_sales_catalog, 0)) AS total_sales_combined
    FROM 
        item i
    LEFT JOIN 
        sales_data sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        catalog_data cd ON i.i_item_sk = cd.cs_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    (CASE 
        WHEN total_web_quantity > 0 AND total_catalog_quantity > 0 THEN 'Both Channels'
        WHEN total_web_quantity > 0 THEN 'Web Only'
        WHEN total_catalog_quantity > 0 THEN 'Catalog Only'
        ELSE 'No Sales'
    END) AS sales_channel,
    total_sales_combined,
    (SELECT COUNT(DISTINCT c.c_customer_sk)
     FROM customer c
     WHERE c.c_current_cdemo_sk IN (
         SELECT cd.cd_demo_sk 
         FROM customer_demographics cd 
         WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
     )) AS married_female_customers,
    (SELECT COUNT(*)
     FROM inventory inv
     WHERE inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand < 0
    ) AS negative_or_null_inventory
FROM 
    item_stats i
WHERE 
    total_sales_combined > (
        SELECT AVG(total_sales_combined) 
        FROM item_stats
    )
ORDER BY 
    total_sales_combined DESC
LIMIT 10;

