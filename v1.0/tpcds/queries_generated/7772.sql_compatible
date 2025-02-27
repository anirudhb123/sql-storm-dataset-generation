
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2022 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
    HAVING 
        SUM(ws.ws_ext_sales_price) > 10000
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    w.web_site_id,
    w.web_name,
    w.web_manager,
    tws.total_sales
FROM 
    web_site w
JOIN 
    TopWebSites tws ON w.web_site_id = tws.web_site_id
ORDER BY 
    tws.total_sales DESC;
