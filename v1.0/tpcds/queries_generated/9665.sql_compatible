
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        c.cd_gender AS customer_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, c.cd_gender
),
shipping_summary AS (
    SELECT 
        d.d_year AS shipping_year,
        d.d_month_seq AS shipping_month,
        sm.sm_type AS ship_mode,
        COUNT(ws.ws_order_number) AS total_shipments,
        SUM(ws.ws_ext_ship_cost) AS total_shipping_cost
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, sm.sm_type
)
SELECT 
    ss.sales_year,
    ss.sales_month,
    ss.customer_gender,
    ss.total_sales,
    ss.order_count,
    ss.avg_net_profit,
    ship.shipping_year,
    ship.shipping_month,
    ship.ship_mode,
    ship.total_shipments,
    ship.total_shipping_cost
FROM 
    sales_summary ss
JOIN 
    shipping_summary ship ON ss.sales_year = ship.shipping_year AND ss.sales_month = ship.shipping_month
ORDER BY 
    ss.sales_year, ss.sales_month, ss.customer_gender, ship.ship_mode;
