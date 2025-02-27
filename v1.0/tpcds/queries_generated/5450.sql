
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        w.web_state = 'CA' 
        AND d.d_year = 2022 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
),
shipping_summary AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_ext_ship_cost) AS avg_shipping_cost
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    s.web_site_id,
    s.total_sales,
    s.total_profit,
    s.total_orders,
    s.unique_customers,
    ship.ship_mode_id,
    ship.order_count,
    ship.avg_shipping_cost
FROM 
    sales_summary s
JOIN 
    shipping_summary ship ON s.total_orders = ship.order_count
ORDER BY 
    s.total_sales DESC, 
    ship.avg_shipping_cost ASC
LIMIT 10;
