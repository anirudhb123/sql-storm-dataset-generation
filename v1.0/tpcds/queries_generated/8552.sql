
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws_sold_date_sk,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name, ws_sold_date_sk
),
TopWebsites AS (
    SELECT 
        web_site_sk,
        web_name,
        total_revenue,
        total_orders
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)

SELECT 
    tw.web_name,
    tw.total_revenue,
    tw.total_orders,
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    TopWebsites tw
JOIN 
    web_sales ws ON tw.web_site_sk = ws.ws_web_site_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    tw.web_name, tw.total_revenue, tw.total_orders, cd.cd_gender
ORDER BY 
    tw.total_revenue DESC;
