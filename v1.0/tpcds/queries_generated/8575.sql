
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_net_profit,
        RANK() OVER (ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.date_sk
    JOIN 
        customer_address ca ON ws.ship_addr_sk = ca.address_sk
    JOIN 
        customer_demographics cd ON ws.bill_cdemo_sk = cd.demo_sk
    WHERE 
        dd.year = 2023 AND
        (cd.gender = 'F' AND cd.marital_status = 'M')  -- Filter for married female customers
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_orders,
        total_net_profit
    FROM 
        RankedSales 
    WHERE 
        profit_rank <= 5
)
SELECT 
    tw.web_site_id,
    tw.total_orders,
    tw.total_net_profit,
    ca.city,
    ca.state,
    ca.country
FROM 
    TopWebSites tw
JOIN 
    web_site ws ON tw.web_site_id = ws.web_site_id
JOIN 
    customer_address ca ON ws.street_number = ca.street_number
WHERE 
    ca.country = 'USA'
ORDER BY 
    tw.total_net_profit DESC;
