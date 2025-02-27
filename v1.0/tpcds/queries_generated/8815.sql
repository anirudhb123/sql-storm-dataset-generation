
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws 
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq IN (1, 2, 3)
        AND ws.ws_ship_mode_sk IN (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_type = 'EXPRESS')
    GROUP BY 
        ws.web_site_id, ws.ws_web_site_sk
),
TopWebSites AS (
    SELECT 
        web_site_id, 
        total_sales, 
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_sales_price) AS total_customer_spent
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
)
SELECT 
    tw.web_site_id,
    tw.total_sales,
    tw.order_count,
    COUNT(DISTINCT cs.c_customer_id) AS unique_customers,
    AVG(cs.total_customer_spent) AS avg_spent_per_customer
FROM 
    TopWebSites tw
LEFT JOIN 
    CustomerSales cs ON cs.total_customer_spent > 0
GROUP BY 
    tw.web_site_id, tw.total_sales, tw.order_count
ORDER BY 
    tw.total_sales DESC;
