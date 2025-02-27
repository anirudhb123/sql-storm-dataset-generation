
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER(PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 90 AND (SELECT MAX(d_date_sk) FROM date_dim)
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_net_paid > 100
    GROUP BY 
        c.c_customer_id
),
TopWebsites AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.web_site_sk
    HAVING 
        SUM(ws.ws_net_paid) > 10000
)
SELECT 
    r.web_site_sk,
    r.ws_order_number,
    r.ws_quantity,
    r.ws_sales_price,
    r.ws_net_paid,
    cs.total_orders,
    cs.total_spent,
    tw.total_sales AS top_website_sales
FROM 
    RankedSales r
LEFT JOIN 
    CustomerStats cs ON r.ws_order_number = cs.total_orders
LEFT JOIN 
    TopWebsites tw ON r.web_site_sk = tw.web_site_sk
WHERE 
    r.rnk <= 10
ORDER BY 
    r.ws_net_paid DESC
LIMIT 50;
