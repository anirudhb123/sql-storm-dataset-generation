
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id
),
TopSales AS (
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
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ts.total_sales,
    ts.order_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    TopSales ts ON ci.cd_purchase_estimate BETWEEN 100 AND 500
WHERE 
    (ci.cd_gender = 'M' OR ci.cd_marital_status = 'S') 
    AND ts.total_sales IS NOT NULL
ORDER BY 
    ts.total_sales DESC;
