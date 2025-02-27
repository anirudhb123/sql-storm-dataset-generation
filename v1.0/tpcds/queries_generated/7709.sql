
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        d.d_year, 
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.web_site_id, d.d_year
),
PromotionStats AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_id
)
SELECT 
    sd.web_site_id,
    sd.d_year,
    sd.total_sales,
    sd.order_count,
    sd.avg_sales_price,
    ps.promo_order_count,
    ps.promo_sales
FROM 
    SalesData sd
LEFT JOIN 
    PromotionStats ps ON sd.web_site_id = ps.promo_order_count
ORDER BY 
    sd.d_year, sd.total_sales DESC
LIMIT 100;
