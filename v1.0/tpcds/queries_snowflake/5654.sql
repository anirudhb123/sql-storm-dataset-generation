
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk
),
PromotionStats AS (
    SELECT 
        p.p_promo_sk,
        COUNT(ws.ws_order_number) AS promo_usage_count,
        SUM(ws.ws_ext_sales_price) AS total_promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk 
    GROUP BY 
        p.p_promo_sk
),
DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk 
    GROUP BY 
        d.d_date
)
SELECT 
    ca.ca_city,
    SUM(cs.total_quantity) AS city_total_quantity,
    SUM(cs.total_sales) AS city_total_sales,
    MAX(ps.promo_usage_count) AS max_promo_usage,
    AVG(ds.daily_sales) AS avg_daily_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
JOIN 
    PromotionStats ps ON cs.c_customer_sk IN (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_promo_sk = ps.p_promo_sk)
JOIN 
    DailySales ds ON ds.daily_sales IS NOT NULL
GROUP BY 
    ca.ca_city
ORDER BY 
    city_total_sales DESC, city_total_quantity DESC;
