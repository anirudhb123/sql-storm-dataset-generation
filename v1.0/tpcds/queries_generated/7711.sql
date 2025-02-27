
WITH OrderStatistics AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        AVG(ws.sales_price) AS avg_sales_price,
        MAX(ws.sold_date_sk) AS last_order_date
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.date_sk
    JOIN 
        item i ON ws.item_sk = i.item_sk
    WHERE 
        cd.gender = 'F' AND 
        cd.education_status IN ('Bachelors', 'Masters') AND 
        dd.year = 2023
    GROUP BY 
        ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_orders,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank
    FROM 
        OrderStatistics
)
SELECT 
    w.web_site_name,
    t.total_orders,
    t.total_profit,
    t.rank
FROM 
    TopWebsites t
JOIN 
    web_site w ON t.web_site_id = w.web_site_id
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_profit DESC;
