
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
)
SELECT 
    w.web_site_name,
    tw.total_net_profit
FROM 
    web_site w
JOIN 
    TopWebSites tw ON w.web_site_id = tw.web_site_id
ORDER BY 
    tw.total_net_profit DESC;
