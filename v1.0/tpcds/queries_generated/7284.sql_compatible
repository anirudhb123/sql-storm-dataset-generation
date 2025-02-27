
WITH sales_summary AS (
    SELECT 
        ws.ship_mode_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.cd_purchase_estimate BETWEEN ib.lower_bound AND ib.upper_bound
    WHERE 
        cd.cd_gender = 'F'
        AND c.c_birth_year >= 1980 
        AND c.c_birth_year <= 1990
    GROUP BY 
        ws.ship_mode_sk
),
top_sales AS (
    SELECT 
        ship_mode_sk,
        total_sales,
        total_orders,
        avg_net_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    ts.total_sales,
    ts.total_orders,
    ts.avg_net_profit
FROM 
    top_sales ts
JOIN 
    ship_mode sm ON ts.ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    ts.sales_rank <= 5
ORDER BY 
    ts.total_sales DESC;
