
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id
),
customer_data AS (
    SELECT 
        ca.ca_country,
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country IS NOT NULL
    GROUP BY ca.ca_country, cd.cd_gender
),
inventory_data AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        SUM(CASE WHEN inv.inv_quantity_on_hand < 0 THEN 1 ELSE 0 END) AS negative_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    sd.web_site_id,
    cd.ca_country,
    cd.cd_gender,
    sd.total_quantity,
    sd.total_sales,
    sd.avg_net_profit,
    cd.customer_count,
    id.total_inventory,
    id.negative_inventory
FROM sales_data sd
FULL OUTER JOIN customer_data cd ON sd.web_site_id IS NOT NULL
FULL OUTER JOIN inventory_data id ON sd.total_quantity IS NOT NULL
WHERE sd.total_sales > 1000
  AND (cd.customer_count < 50 OR cd.cd_gender IS NULL)
ORDER BY sd.total_sales DESC, cd.ca_country, cd.cd_gender;
