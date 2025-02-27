
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer AS cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
    WHERE 
        dd.d_year = 2023 AND 
        cust.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.web_site_id, ws_sold_date_sk
),
TotalSales AS (
    SELECT 
        web_site_id, 
        SUM(total_profit) AS yearly_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank = 1
    GROUP BY 
        web_site_id
)
SELECT 
    ws.web_site_id, 
    ws.web_name, 
    ts.yearly_profit
FROM 
    web_site AS ws
JOIN 
    TotalSales AS ts ON ws.web_site_id = ts.web_site_id
ORDER BY 
    ts.yearly_profit DESC
LIMIT 10;
