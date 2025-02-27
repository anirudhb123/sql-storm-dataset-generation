
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        AVG(ws.ws_net_paid_inc_ship_tax) AS avg_order_value
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE dd.d_year = 2022
    AND cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
    GROUP BY ws.web_site_id
), InventoryData AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    sd.web_site_id,
    sd.total_net_profit,
    sd.total_orders,
    sd.unique_customers,
    sd.avg_order_value,
    id.total_inventory
FROM SalesData sd
JOIN InventoryData id ON sd.web_site_id = id.i_item_id
ORDER BY sd.total_net_profit DESC
LIMIT 10;
