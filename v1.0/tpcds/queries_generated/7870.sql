
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk, 
        wd.warehouse_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse wd ON ws.ws_warehouse_sk = wd.warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, 
        wd.warehouse_sk
),
customer_summary AS (
    SELECT 
        cd.cd_demo_sk, 
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
promotion_summary AS (
    SELECT 
        p.p_promo_sk, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders_using_promo,
        SUM(ws.ws_ext_sales_price) AS total_sales_from_promo
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
),
final_report AS (
    SELECT 
        ss.web_site_sk, 
        ss.total_quantity_sold, 
        ss.total_net_profit, 
        cs.total_customers, 
        cs.avg_purchase_estimate, 
        ps.total_orders_using_promo, 
        ps.total_sales_from_promo
    FROM 
        sales_summary ss
    JOIN 
        customer_summary cs ON ss.web_site_sk = cs.cd_demo_sk
    JOIN 
        promotion_summary ps ON ss.web_site_sk = ps.p_promo_sk
)
SELECT 
    f.web_site_sk,
    f.total_quantity_sold,
    f.total_net_profit,
    f.total_customers,
    f.avg_purchase_estimate,
    f.total_orders_using_promo,
    f.total_sales_from_promo
FROM 
    final_report f
ORDER BY 
    f.total_net_profit DESC
LIMIT 10;
