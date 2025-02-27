
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        COALESCE(SUM(ws_net_profit), 0) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY COALESCE(SUM(ws_net_profit), 0) DESC) AS sales_rank
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990 
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws.web_site_sk, ws.order_number
),
shipping_costs AS (
    SELECT 
        sr_order_number,
        SUM(sr_return_ship_cost) AS total_return_ship_cost
    FROM 
        store_returns
    GROUP BY 
        sr_order_number
),
final_stats AS (
    SELECT 
        r.web_site_sk,
        r.order_number,
        r.total_net_profit,
        COALESCE(s.total_return_ship_cost, 0) AS total_ship_cost,
        r.sales_rank
    FROM 
        ranked_sales r
    FULL OUTER JOIN 
        shipping_costs s ON r.order_number = s.sr_order_number
)
SELECT 
    fs.web_site_sk,
    fs.order_number,
    fs.total_net_profit,
    fs.total_ship_cost,
    CASE 
        WHEN fs.total_net_profit IS NULL THEN 'No Profit'
        WHEN fs.total_net_profit > fs.total_ship_cost THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_loss_status,
    LAG(fs.total_net_profit) OVER (PARTITION BY fs.web_site_sk ORDER BY fs.sales_rank) AS previous_net_profit,
    RANK() OVER (ORDER BY fs.total_net_profit DESC) AS overall_rank
FROM 
    final_stats fs
WHERE 
    fs.sales_rank IS NOT NULL
    AND (fs.total_net_profit IS NOT NULL OR fs.total_ship_cost > 0)
ORDER BY 
    fs.total_net_profit DESC NULLS LAST;
