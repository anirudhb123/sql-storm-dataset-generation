
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_revenue,
        AVG(ws.ws_sales_price) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND c.c_birth_year BETWEEN 1970 AND 1980
    GROUP BY 
        ws.web_site_id
)
SELECT 
    r.web_site_id,
    r.total_orders,
    r.total_revenue,
    r.avg_order_value
FROM 
    RankedSales r
WHERE 
    r.rank = 1
ORDER BY 
    r.total_revenue DESC
LIMIT 5;
