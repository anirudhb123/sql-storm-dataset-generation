
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
high_profit_websites AS (
    SELECT 
        web_site_sk,
        web_name,
        total_quantity,
        total_profit
    FROM 
        ranked_sales
    WHERE 
        profit_rank <= 5
)
SELECT 
    hw.web_name,
    hw.total_quantity,
    hw.total_profit,
    d.d_month,
    d.d_year
FROM 
    high_profit_websites hw
JOIN 
    date_dim d ON d.d_year = 2022
ORDER BY 
    hw.total_profit DESC;
