
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
ItemInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        i.i_item_desc,
        SUM(sd.total_profit) OVER () AS grand_total_profit
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.total_profit > 0
    ORDER BY 
        sd.total_profit DESC
    LIMIT 10
)

SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_profit,
    tsi.grand_total_profit,
    CASE 
        WHEN tsi.total_profit IS NULL THEN 'No Profit'
        ELSE CONCAT('$', ROUND(tsi.total_profit, 2))
    END AS formatted_profit,
    COALESCE(ii.total_inventory, 0) AS inventory_remaining
FROM 
    RankedCustomers rc
LEFT JOIN 
    TopSellingItems tsi ON rc.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = tsi.ws_item_sk LIMIT 1)
LEFT JOIN 
    ItemInventory ii ON tsi.ws_item_sk = ii.inv_item_sk
WHERE 
    rc.rank <= 5
ORDER BY 
    rc.cd_gender, tsi.total_profit DESC;
