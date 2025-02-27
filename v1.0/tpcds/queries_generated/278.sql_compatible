
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_per_site
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_rec_start_date IS NOT NULL
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT 
        web_site_sk, 
        total_quantity, 
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        rank_per_site <= 3
),
MonthlySales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS monthly_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
    ORDER BY 
        d.d_year
)
SELECT 
    t.web_site_sk,
    t.total_quantity,
    t.total_net_profit,
    m.d_year,
    m.monthly_profit,
    COALESCE(m.monthly_profit, 0) AS adjusted_monthly_profit,
    CASE 
        WHEN m.monthly_profit IS NULL THEN 'No Sales'
        WHEN m.monthly_profit > 1000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    TopWebsites t
FULL OUTER JOIN 
    MonthlySales m ON t.web_site_sk = m.d_year
WHERE 
    t.total_quantity > 50 OR m.monthly_profit > 2000
ORDER BY 
    t.total_net_profit DESC, m.d_year DESC;
