
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND d.d_year = 2023 
        AND d.d_moy IN (11, 12) 
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.web_site_id,
    t.total_sales,
    t.order_count,
    wa.w_warehouse_name,
    wa.w_city
FROM 
    TopWebSites t
JOIN 
    web_site w ON t.web_site_id = w.web_site_id
JOIN 
    warehouse wa ON w.web_company_id = wa.w_warehouse_sk
ORDER BY 
    t.total_sales DESC;
