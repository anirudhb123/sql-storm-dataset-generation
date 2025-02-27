
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
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
        total_orders,
        total_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
)
SELECT 
    tw.web_site_id,
    tw.total_orders,
    tw.total_profit,
    (SELECT COUNT(DISTINCT ss.ticket_number) 
     FROM store_sales ss 
     JOIN store s ON ss.store_sk = s.s_store_sk 
     WHERE s.state = 'CA') AS total_ca_store_sales,
    (SELECT SUM(ss.net_profit) 
     FROM store_sales ss 
     JOIN store s ON ss.store_sk = s.s_store_sk 
     WHERE s.city = 'Los Angeles') AS total_la_store_profit
FROM 
    TopWebSites tw;
