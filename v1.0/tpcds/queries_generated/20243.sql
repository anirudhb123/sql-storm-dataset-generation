
WITH customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'No Dependents'
            ELSE CAST(cd.cd_dep_count AS VARCHAR)
        END AS dependent_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_gender
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
inventory_info AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        COALESCE(SUM(NULLIF(inv.inv_quantity_on_hand, 0)), 0) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    si.total_sales,
    si.number_of_sales,
    ii.total_inventory,
    CASE 
        WHEN si.total_sales IS NOT NULL AND ii.total_inventory > 0 THEN 'Available'
        ELSE 'Not Available'
    END AS stock_status,
    CURRENT_TIMESTAMP AS query_generated_at
FROM 
    customer_info ci
LEFT JOIN 
    sales_data si ON ci.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk = ci.c_customer_id LIMIT 1)
LEFT JOIN 
    inventory_info ii ON si.ws_item_sk = ii.inv_item_sk
WHERE 
    ci.rank_gender = 1
    AND (ci.dependent_count = 'No Dependents' OR ci.cd_marital_status IS NULL)
ORDER BY 
    ci.c_last_name, ci.c_first_name, si.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
