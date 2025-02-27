
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_current_cdemo_sk, 
        0 AS level
    FROM 
        customer
    WHERE 
        c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_cdemo_sk, 
        ch.level + 1 
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
), 
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
), 
InventoryData AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.total_quantity, 0) AS total_sales,
    COALESCE(rd.total_return_quantity, 0) AS total_returns,
    COALESCE(id.total_inventory, 0) AS inventory,
    COALESCE(sd.total_profit, 0) AS total_profit,
    (COALESCE(sd.total_profit, 0) - COALESCE(rd.total_return_loss, 0)) AS net_profit,
    CASE 
        WHEN COALESCE(sd.total_quantity, 0) > 0 THEN (COALESCE(rd.total_return_quantity, 0) * 100.0) / COALESCE(sd.total_quantity, 1)
        ELSE NULL 
    END AS return_rate,
    (SELECT COUNT(DISTINCT ch.c_customer_sk) 
     FROM CustomerHierarchy ch 
     WHERE ch.c_current_cdemo_sk IS NOT NULL) AS total_customers,
    (SELECT COUNT(DISTINCT ws.ws_order_number)
     FROM web_sales ws
     WHERE ws.ws_ship_date_sk = (SELECT MAX(ws2.ws_ship_date_sk) FROM web_sales ws2)) AS recent_orders
FROM 
    item i
LEFT JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    ReturnData rd ON i.i_item_sk = rd.wr_item_sk
LEFT JOIN 
    InventoryData id ON i.i_item_sk = id.inv_item_sk
WHERE 
    i.i_current_price IS NOT NULL AND 
    (i.i_item_desc LIKE '%special%' OR i.i_item_id IN (SELECT p.p_item_sk FROM promotion p WHERE p.p_discount_active = 'Y'))
ORDER BY 
    net_profit DESC
LIMIT 100;
