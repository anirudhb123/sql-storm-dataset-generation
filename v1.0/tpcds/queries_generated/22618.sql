
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT CASE WHEN cd.cd_gender = 'F' THEN ws.ws_order_number END) AS female_orders,
        COUNT(DISTINCT CASE WHEN cd.cd_gender = 'M' THEN ws.ws_order_number END) AS male_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ws.web_site_id
), 
date_filter AS (
    SELECT 
        d.d_date_sk
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2023 AND 
        (d.d_week_seq = 1 OR d.d_week_seq = 52 OR d.d_fy_week_seq = 1)
), 
total_inventory AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
), 
unique_returns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    ss.web_site_id,
    ss.total_net_profit,
    ss.total_orders,
    COALESCE(u_female_orders.female_orders, 0) AS female_orders,
    COALESCE(u_male_orders.male_orders, 0) AS male_orders,
    iv.total_quantity,
    COALESCE(ur.total_returns, 0) AS store_returns,
    CASE 
        WHEN ss.total_net_profit IS NULL THEN 'No Profit'
        WHEN ss.total_net_profit > 0 AND ss.female_orders > ss.male_orders THEN 'Female Dominant'
        ELSE 'Male Dominant'
    END AS demographic_summary
FROM 
    sales_summary ss
LEFT JOIN 
    (SELECT web_site_id, female_orders FROM sales_summary WHERE profit_rank = 1) u_female_orders ON ss.web_site_id = u_female_orders.web_site_id
LEFT JOIN 
    (SELECT web_site_id, male_orders FROM sales_summary WHERE profit_rank = 1) u_male_orders ON ss.web_site_id = u_male_orders.web_site_id
LEFT JOIN 
    total_inventory iv ON iv.i_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_filter d))
LEFT JOIN 
    unique_returns ur ON ur.sr_store_sk = (SELECT MIN(sr_store_sk) FROM store_returns)
WHERE 
    ss.total_net_profit IS NOT NULL AND 
    ss.total_orders > 5
ORDER BY 
    ss.total_net_profit DESC;
