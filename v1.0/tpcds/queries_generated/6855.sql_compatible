
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws_sold_date_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'M'
        AND ws.ws_sold_date_sk BETWEEN 2458439 AND 2458765
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
TopWebSites AS (
    SELECT 
        web_site_sk,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 3
)
SELECT 
    w.web_site_id, 
    w.web_name, 
    t.total_sales
FROM 
    TopWebSites t
JOIN 
    web_site w ON t.web_site_sk = w.web_site_sk
ORDER BY 
    t.total_sales DESC;
