
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        WS.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        customer.c_current_cdemo_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) as sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer ON ws.ws_bill_customer_sk = customer.c_customer_sk
),

total_sales AS (
    SELECT 
        web_site_sk,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS avg_price
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
    GROUP BY 
        web_site_sk 
),

most_profitable AS (
    SELECT 
        ts.web_site_sk,
        ts.total_profit,
        ts.avg_price,
        CASE 
            WHEN ts.total_profit > 10000 THEN 'High Profit'
            WHEN ts.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM 
        total_sales ts
)

SELECT 
    mp.web_site_sk,
    mp.total_profit,
    mp.avg_price,
    mp.profit_category,
    COUNT(rs.c_current_cdemo_sk) AS customer_count,
    MAX(rs.ws_net_profit) AS highest_profit,
    MIN(rs.ws_net_profit) AS lowest_profit
FROM 
    most_profitable mp
LEFT JOIN 
    ranked_sales rs ON mp.web_site_sk = rs.web_site_sk AND rs.sales_rank <= 10
GROUP BY 
    mp.web_site_sk, mp.total_profit, mp.avg_price, mp.profit_category
HAVING 
    COUNT(rs.c_current_cdemo_sk) > 5
ORDER BY 
    mp.total_profit DESC;
