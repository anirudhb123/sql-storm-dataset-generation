
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
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id, 
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 5
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_net_profit > 0
    GROUP BY 
        c.c_customer_id
)
SELECT 
    tw.web_site_id,
    tw.total_net_profit,
    cs.order_count,
    cs.avg_net_profit
FROM 
    TopWebsites tw
JOIN 
    CustomerStatistics cs ON tw.web_site_id = cs.c_customer_id
ORDER BY 
    tw.total_net_profit DESC;
