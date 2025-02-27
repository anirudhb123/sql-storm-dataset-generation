
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT 
        r.web_site_sk,
        r.total_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.rank <= 10
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS customer_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.customer_net_profit,
        RANK() OVER (ORDER BY cs.customer_net_profit DESC) AS rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.customer_net_profit > 0
)
SELECT 
    tw.web_site_sk,
    tw.total_net_profit,
    tc.c_customer_sk,
    tc.order_count,
    tc.customer_net_profit
FROM 
    TopWebsites tw
JOIN 
    TopCustomers tc ON tw.total_net_profit > 0
ORDER BY 
    tw.total_net_profit DESC, tc.customer_net_profit DESC;
