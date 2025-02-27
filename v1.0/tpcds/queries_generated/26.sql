
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
ItemInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COALESCE(SUM(ws.ws_sales_price), 0) AS total_spent,
    ir.total_sales,
    ii.total_inventory,
    CASE 
        WHEN ii.total_inventory > 0 THEN 'In Stock'
        ELSE 'Out of Stock'
    END AS stock_status
FROM 
    CustomerData cs
LEFT JOIN 
    web_sales ws ON cs.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    RankedSales ir ON ws.ws_item_sk = ir.ws_item_sk AND ir.sales_rank = 1
LEFT JOIN 
    ItemInventory ii ON ws.ws_item_sk = ii.inv_item_sk
WHERE 
    cs.cd_income_band_sk IS NOT NULL
GROUP BY 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    ir.total_sales, 
    ii.total_inventory
HAVING 
    total_spent > 1000
ORDER BY 
    total_spent DESC
LIMIT 100;
