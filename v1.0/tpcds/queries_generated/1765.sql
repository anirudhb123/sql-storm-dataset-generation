
WITH sales_data AS (
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        ws.sold_date_sk, ws.item_sk
),
inventory_data AS (
    SELECT 
        inv.inv_date_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_date_sk, inv.inv_item_sk
),
sales_inventory AS (
    SELECT 
        sd.sold_date_sk,
        sd.item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(id.total_inventory, 0) AS total_inventory,
        CASE 
            WHEN COALESCE(id.total_inventory, 0) = 0 THEN NULL
            ELSE sd.total_sales / COALESCE(id.total_inventory, 1) 
        END AS sales_per_inventory
    FROM 
        sales_data sd
    LEFT JOIN 
        inventory_data id ON sd.sold_date_sk = id.inv_date_sk AND sd.item_sk = id.inv_item_sk
)
SELECT 
    si.sold_date_sk,
    si.item_sk,
    si.total_quantity,
    si.total_sales,
    si.total_inventory,
    si.sales_per_inventory,
    RANK() OVER (ORDER BY si.sales_per_inventory DESC) AS inventory_sales_rank
FROM 
    sales_inventory si
WHERE 
    si.sales_per_inventory IS NOT NULL
ORDER BY 
    si.sales_per_inventory DESC
LIMIT 10;
