
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_net_paid_inc_tax) - MIN(ws.ws_net_paid_inc_tax) AS profit_variance,
        CASE 
            WHEN COUNT(DISTINCT ws.ws_order_number) = 0 THEN NULL 
            ELSE SUM(ws.ws_net_profit) / NULLIF(COUNT(DISTINCT ws.ws_order_number), 0) 
        END AS avg_profit_per_order
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
HighProfit AS (
    SELECT 
        web_site_id,
        total_net_profit,
        profit_rank,
        total_orders,
        profit_variance,
        avg_profit_per_order
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 5
),
LowOrderSites AS (
    SELECT 
        ws.web_site_id,
        ws.total_orders
    FROM 
        RankedSales ws
    WHERE 
        total_orders < 10
)
SELECT 
    hp.web_site_id,
    hp.total_net_profit,
    COALESCE(los.total_orders, 0) AS low_order_count,
    hp.profit_variance,
    hp.avg_profit_per_order,
    CASE 
        WHEN hp.total_net_profit > 1000 AND hp.total_orders > 10 THEN 'High Value'
        WHEN hp.total_net_profit > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    HighProfit hp
LEFT JOIN 
    LowOrderSites los ON hp.web_site_id = los.web_site_id
UNION ALL
SELECT 
    'General Summary' AS web_site_id,
    SUM(total_net_profit) AS total_net_profit,
    NULL AS low_order_count,
    CASE 
        WHEN AVG(profit_variance) IS NULL THEN NULL 
        ELSE ROUND(AVG(profit_variance), 2) 
    END AS avg_profit_variance,
    NULL AS avg_profit_per_order,
    CASE 
        WHEN SUM(total_net_profit) > 5000 THEN 'High Value'
        ELSE 'Low Value'
    END AS overall_value
FROM 
    HighProfit
GROUP BY 
    'General Summary'
HAVING 
    COUNT(*) > 1;
