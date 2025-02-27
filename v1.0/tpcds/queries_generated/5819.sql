
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id, 
        ws.ws_web_site_sk
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    tw.web_site_id,
    tw.total_sales,
    tw.order_count,
    (SELECT COUNT(DISTINCT c.c_customer_id) FROM web_sales ws2 JOIN customer c2 ON c2.c_customer_sk = ws2.ws_bill_customer_sk WHERE ws2.ws_web_site_sk = tw.web_site_id) AS unique_customers
FROM 
    TopWebsites tw
ORDER BY 
    tw.total_sales DESC;
