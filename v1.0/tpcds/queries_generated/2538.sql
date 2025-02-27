
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_units_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
customer_data AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state,
        ROUND(AVG(cd.cd_dep_count), 2) AS avg_dependents
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, ca.ca_state
),
inventory_analysis AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        MAX(i.i_current_price) AS max_price,
        MIN(i.i_current_price) AS min_price,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
)
SELECT 
    ss.web_name,
    ss.total_net_profit,
    ss.total_orders,
    ss.total_units_sold,
    cd.cd_gender,
    cd.ed_marital_status,
    cd.avg_dependents,
    ia.i_item_id,
    ia.max_price,
    ia.min_price,
    ia.warehouse_count
FROM 
    sales_summary ss
JOIN 
    customer_data cd ON ss.web_site_sk IN (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL)
JOIN 
    inventory_analysis ia ON ss.total_units_sold > (SELECT AVG(total_units_sold) FROM sales_summary) 
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    ss.total_net_profit DESC, 
    ia.max_price DESC;
