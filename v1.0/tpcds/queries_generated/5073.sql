
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_education_status IN ('PhD', 'Masters') AND 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws.web_site_id
), TopSites AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales,
        avg_net_paid,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        SalesSummary
)
SELECT 
    t.web_site_id,
    t.total_quantity,
    t.total_sales,
    t.avg_net_paid
FROM 
    TopSites t
WHERE 
    t.rank <= 5
ORDER BY 
    t.total_sales DESC;
