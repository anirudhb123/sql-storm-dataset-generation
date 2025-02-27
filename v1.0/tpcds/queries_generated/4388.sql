
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    is.total_sales,
    is.avg_price,
    COALESCE(is.total_sales, 0) AS sales_count,
    COALESCE(inv.total_inventory, 0) AS inventory_count,
    CASE 
        WHEN COALESCE(is.total_sales, 0) > 100 THEN 'High Seller'
        ELSE 'Low Seller'
    END AS sales_category
FROM 
    customer_details cd
LEFT JOIN 
    item_sales is ON cd.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE cd.c_customer_sk = c.c_customer_sk LIMIT 1)
LEFT JOIN 
    inventory_summary inv ON is.ws_item_sk = inv.inv_item_sk
WHERE 
    cd.rank = 1
ORDER BY 
    cd.c_first_name, 
    cd.c_last_name;
