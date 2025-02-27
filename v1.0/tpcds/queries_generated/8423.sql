
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR')
    GROUP BY 
        ws.web_site_id
),
promotion_summary AS (
    SELECT 
        p.p_promo_id,
        SUM(cs.cs_ext_sales_price) AS promo_sales,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_quantity) AS total_quantity 
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    WHERE 
        p.p_start_date_sk >= 20230101 
        AND p.p_end_date_sk <= 20231231
    GROUP BY 
        p.p_promo_id
)
SELECT 
    ss.web_site_id,
    ss.total_quantity AS website_sales_quantity,
    ss.total_sales AS website_sales_total,
    ss.avg_profit AS website_avg_profit,
    ps.promo_sales,
    ps.total_orders AS promo_orders,
    ps.total_quantity AS promo_quantity
FROM 
    sales_summary ss
LEFT JOIN 
    promotion_summary ps ON ss.web_site_id = ps.p_promo_id
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
