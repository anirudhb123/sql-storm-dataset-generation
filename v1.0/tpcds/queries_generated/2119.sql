
WITH demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
    GROUP BY 
        ws.ws_ship_date_sk
),
daily_sales AS (
    SELECT 
        ds.d_date_id,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        COALESCE(ss.total_orders, 0) AS total_orders
    FROM 
        date_dim ds
    LEFT JOIN 
        sales_summary ss ON ds.d_date_sk = ss.ws_ship_date_sk
)
SELECT 
    ds.d_date_id,
    ds.total_net_profit,
    ds.total_orders,
    ds.total_net_profit / NULLIF(ds.total_orders, 0) AS avg_order_profit,
    ds.total_orders / NULLIF((SELECT COUNT(DISTINCT c_customer_sk) FROM customer), 0) AS total_customers,
    ds.total_net_profit / COUNT(DISTINCT cd.cd_demo_sk) OVER() AS profit_per_demographic
FROM 
    daily_sales ds
JOIN 
    demographic_summary cd ON 1=1
WHERE 
    ds.total_net_profit > (SELECT AVG(total_net_profit) FROM daily_sales)
ORDER BY 
    ds.d_date_id;
