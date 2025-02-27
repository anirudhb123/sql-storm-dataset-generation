
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_web_site_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_web_site_sk
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
), detailed_sales AS (
    SELECT 
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws.ws_ext_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.total_net_profit) AS total_profit,
    MAX(cs.total_revenue) AS max_revenue,
    AVG(ds.total_quantity_sold) AS avg_quantity_sold,
    ds.sm_type
FROM 
    customer_info c
JOIN sales_summary ss ON c.c_customer_sk = ss.ws_sold_date_sk
LEFT JOIN detailed_sales ds ON ss.ws_web_site_sk = ds.sm_type
GROUP BY 
    c.c_first_name, c.c_last_name, ds.sm_type
HAVING 
    SUM(ss.total_net_profit) > 1000
ORDER BY 
    total_profit DESC;
