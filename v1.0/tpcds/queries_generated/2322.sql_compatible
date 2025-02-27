
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAnalysis AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk
),
InventoryDetails AS (
    SELECT 
        inv.inv_item_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity,
        MAX(inv.inv_quantity_on_hand) AS max_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    ra.total_net_profit,
    ra.total_orders,
    id.avg_quantity,
    id.max_quantity,
    CASE 
        WHEN rc.rn <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    RankedCustomers rc
LEFT JOIN 
    SalesAnalysis ra ON rc.c_customer_id = (
        SELECT DISTINCT ws.ws_bill_customer_sk 
        FROM web_sales ws 
        WHERE ws.ws_item_sk IN (
            SELECT i.i_item_sk 
            FROM item i 
            JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
            WHERE inv.inv_quantity_on_hand > (SELECT AVG(inv_quantity_on_hand) FROM inventory)
        )
    )
LEFT JOIN 
    InventoryDetails id ON id.inv_item_sk = ra.ws_item_sk
WHERE 
    rc.cd_marital_status = 'M' OR rc.cd_gender = 'F'
ORDER BY 
    ra.total_net_profit DESC NULLS LAST;
