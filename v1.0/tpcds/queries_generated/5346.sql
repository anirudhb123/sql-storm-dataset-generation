
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count
    FROM RankedSales 
    WHERE rank <= 5
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN TopWebSites tw ON ws.ws_web_site_id = tw.web_site_id
    GROUP BY c.c_customer_id, cd.cd_gender
)
SELECT 
    cd.cd_gender,
    COUNT(cs.c_customer_id) AS customer_count,
    AVG(cs.total_orders) AS avg_orders,
    AVG(cs.total_spent) AS avg_spent
FROM CustomerStats cs
JOIN customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
GROUP BY cd.cd_gender
ORDER BY customer_count DESC;
