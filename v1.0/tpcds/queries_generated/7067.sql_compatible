
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws 
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk 
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq IN (7, 8) 
    GROUP BY 
        ws.web_site_id
), 
TopWebsites AS (
    SELECT web_site_id, total_sales, order_count 
    FROM RankedSales 
    WHERE rank <= 5
), 
CustomerDetails AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 500
)
SELECT 
    tw.web_site_id, 
    tw.total_sales, 
    tw.order_count, 
    COUNT(DISTINCT cd.c_first_name) AS unique_customers
FROM 
    TopWebsites tw
LEFT JOIN 
    CustomerDetails cd ON cd.cd_purchase_estimate > 500
GROUP BY 
    tw.web_site_id, tw.total_sales, tw.order_count
ORDER BY 
    tw.total_sales DESC;
