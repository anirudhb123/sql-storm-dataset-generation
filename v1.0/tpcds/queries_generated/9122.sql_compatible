
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws.web_site_sk
),
TopWebsites AS (
    SELECT 
        web_site_id, 
        total_sales, 
        order_count 
    FROM 
        RankedSales
    WHERE 
        rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    t.web_site_id,
    t.total_sales,
    t.order_count,
    COUNT(ci.c_customer_sk) AS num_customers,
    AVG(ci.total_spent) AS avg_spent_per_customer
FROM 
    TopWebsites t
LEFT JOIN 
    CustomerInfo ci ON t.total_sales = ci.total_spent
GROUP BY 
    t.web_site_id, t.total_sales, t.order_count
ORDER BY 
    t.total_sales DESC;
