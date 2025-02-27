
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        DATE_ADD(d.d_date, INTERVAL 1 DAY) AS sold_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        cs.cs_ship_mode_sk,
        sm.sm_type AS ship_mode
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    JOIN 
        ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_sold_date_sk, DATE_ADD(d.d_date, INTERVAL 1 DAY), cs.cs_ship_mode_sk, sm.sm_type
),
customer_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_estimated_spending,
        AVG(cd.cd_dep_count) AS average_dependents
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
final_summary AS (
    SELECT 
        s.sold_date,
        ss.total_quantity,
        ss.total_net_profit,
        ss.total_orders,
        cs.total_customers,
        cs.total_estimated_spending,
        cs.average_dependents,
        AVG(cs.average_dependents) OVER () AS overall_average_dependents
    FROM 
        sales_summary ss
    JOIN 
        customer_summary cs ON ss.total_orders > 0
)
SELECT 
    sold_date,
    total_quantity,
    total_net_profit,
    total_orders,
    total_customers,
    total_estimated_spending,
    average_dependents,
    overall_average_dependents
FROM 
    final_summary
WHERE 
    total_net_profit > 1000
ORDER BY 
    sold_date DESC
LIMIT 10;
