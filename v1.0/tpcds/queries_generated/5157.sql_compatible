
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.web_site_id
),
DemographicData AS (
    SELECT 
        cd.cd_gender,
        SUM(cd.cd_dep_count) AS total_dependents,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender
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
    sd.web_site_id,
    sd.total_quantity,
    sd.total_profit,
    sd.total_orders,
    dd.cd_gender,
    dd.total_dependents,
    dd.avg_purchase_estimate,
    id.total_inventory
FROM 
    SalesData sd
JOIN 
    DemographicData dd ON dd.cd_gender IN ('M', 'F')
JOIN 
    InventoryData id ON id.inv_item_sk IN (SELECT WS.ws_item_sk FROM web_sales WS WHERE WS.ws_web_site_sk = sd.web_site_id)
ORDER BY 
    sd.total_profit DESC;
