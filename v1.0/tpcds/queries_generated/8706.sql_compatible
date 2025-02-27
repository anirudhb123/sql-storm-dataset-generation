
WITH demographic_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count,
        AVG(cd_dep_employed_count) AS avg_dep_employed_count,
        AVG(cd_dep_college_count) AS avg_dep_college_count
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_gender, cd_marital_status
),
sales_summary AS (
    SELECT 
        d.d_year,
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY d.d_year, sm.sm_type
),
inventory_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_product_name
),
store_performance AS (
    SELECT 
        s.s_store_name,
        SUM(ss.ss_sales_price) AS total_store_sales,
        SUM(ss.ss_quantity) AS total_store_quantity,
        AVG(ss.ss_net_profit) AS avg_store_net_profit
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_name
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ss.d_year,
    ss.sm_type,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_net_profit,
    is.i_product_name,
    is.total_inventory,
    sp.total_store_sales,
    sp.avg_store_net_profit
FROM demographic_summary ds
JOIN sales_summary ss ON ds.customer_count > 0 
JOIN inventory_summary is ON ds.customer_count > 0 
JOIN store_performance sp ON ds.customer_count > 0
ORDER BY ds.cd_gender, ds.cd_marital_status, ss.d_year, ss.sm_type;
