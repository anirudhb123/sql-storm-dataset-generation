
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id, ws.ws_sold_date_sk
)
SELECT 
    sd.web_site_id,
    COUNT(DISTINCT sd.ws_sold_date_sk) AS sale_days,
    SUM(sd.total_sales) AS total_annual_sales,
    SUM(sd.total_orders) AS total_annual_orders,
    AVG(sd.avg_order_value) AS avg_order_value
FROM 
    SalesData sd
GROUP BY 
    sd.web_site_id
ORDER BY 
    total_annual_sales DESC
LIMIT 10;
