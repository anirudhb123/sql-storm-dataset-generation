
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number
    GROUP BY 
        c.c_customer_id
),
demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_quantity) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_net_profit
    FROM 
        customer_demographics cd
    JOIN 
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
shipping_modes AS (
    SELECT 
        sm.sm_carrier,
        COUNT(ws.ws_order_number) AS total_shipments,
        SUM(ws.ws_net_paid_inc_ship) AS total_revenue
    FROM 
        ship_mode sm
    JOIN 
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_carrier
),
date_range AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    cs.c_customer_id,
    cs.total_web_sales,
    cs.total_orders,
    cs.total_web_returns,
    d.cd_gender,
    d.cd_marital_status,
    d.total_catalog_sales,
    d.total_catalog_net_profit,
    sm.sm_carrier,
    sm.total_shipments,
    sm.total_revenue,
    dr.d_year,
    dr.d_month_seq,
    dr.total_net_profit
FROM 
    customer_sales cs
JOIN 
    demographics d ON cs.c_customer_id = d.cd_demo_sk
JOIN 
    shipping_modes sm ON d.total_catalog_sales > 100
JOIN 
    date_range dr ON dr.total_net_profit > 1000
ORDER BY 
    cs.total_web_sales DESC, dr.total_net_profit DESC
LIMIT 50;
