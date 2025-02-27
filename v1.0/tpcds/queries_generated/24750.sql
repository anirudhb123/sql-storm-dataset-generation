
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        COALESCE(cr.cr_return_quantity, 0) AS return_quantity,
        COALESCE(cr.cr_return_amount, 0) AS return_amount,
        CASE 
            WHEN cr.cr_return_quantity IS NOT NULL THEN 'Returned'
            ELSE 'Sold'
        END AS sales_status
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_returns cr ON ws.ws_order_number = cr.cr_order_number AND ws.ws_item_sk = cr.cr_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
        AND ws.ws_sold_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk IN (SELECT DISTINCT ws.ws_sold_date_sk FROM web_sales ws)
    GROUP BY 
        inv.inv_item_sk
),
FinalReport AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_quantity,
        sd.ws_net_profit,
        sd.return_quantity,
        sd.return_amount,
        CASE 
            WHEN ic.total_inventory IS NULL THEN 'Out of Stock'
            WHEN ic.total_inventory < sd.ws_quantity THEN 'Insufficient Stock'
            ELSE 'Sufficient Stock'
        END AS inventory_status,
        rc.gender_rank
    FROM 
        RankedCustomers rc
    JOIN 
        SalesData sd ON rc.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN 
        InventoryCheck ic ON sd.ws_item_sk = ic.inv_item_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.ws_order_number,
    f.ws_item_sk,
    f.ws_quantity,
    f.ws_net_profit,
    f.return_quantity,
    f.return_amount,
    f.inventory_status,
    f.gender_rank
FROM 
    FinalReport f
WHERE 
    (f.return_quantity > 0 AND f.inventory_status = 'Insufficient Stock')
    OR (f.gender_rank = 1 AND f.inventory_status = 'Sufficient Stock')
ORDER BY 
    f.c_customer_sk, 
    f.ws_order_number DESC;
