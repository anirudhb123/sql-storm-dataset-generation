
WITH RECURSIVE CustomerCTE AS (
    SELECT 
        c_customer_sk,
        c_customer_id,
        c_current_cdemo_sk,
        c_first_name,
        c_last_name,
        c_birth_year,
        ROW_NUMBER() OVER (PARTITION BY c_current_cdemo_sk ORDER BY c_customer_sk) AS rn
    FROM 
        customer 
    WHERE 
        c_birth_year IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_net_profit) AS max_profit
    FROM 
        web_sales ws
    INNER JOIN 
        CustomerCTE c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        COALESCE(sd.total_quantity, 0) AS total_quantity_sold
    FROM 
        inventory inv
    LEFT JOIN 
        SalesData sd ON inv.inv_item_sk = sd.ws_item_sk
)
SELECT 
    CASE 
        WHEN ic.inv_quantity_on_hand - ic.total_quantity_sold < 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS stock_status,
    wd.w_warehouse_name,
    SUM(ic.inv_quantity_on_hand) AS total_inventory,
    SUM(ic.total_quantity_sold) AS total_sold
FROM 
    InventoryCheck ic
JOIN 
    warehouse wd ON wd.w_warehouse_sk = ic.inv_warehouse_sk
GROUP BY 
    wd.w_warehouse_name
HAVING 
    SUM(ic.inv_quantity_on_hand) > 1000 
    AND SUM(ic.total_quantity_sold) > 100
ORDER BY 
    stock_status DESC, 
    total_inventory DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
