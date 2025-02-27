
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
), 
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_sales, 
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000
), 
TopPromotions AS (
    SELECT 
        p.p_promo_name,
        COUNT(*) AS promo_usage
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        p.p_promo_name 
    ORDER BY 
        promo_usage DESC
), 
SalesSummary AS (
    SELECT 
        hc.c_customer_id, 
        hc.total_sales AS customer_sales,
        tp.promo_name,
        tp.promo_usage
    FROM 
        HighValueCustomers hc
    LEFT JOIN 
        (SELECT p.promo_name, COUNT(*) AS promo_usage FROM TopPromotions tp) tp ON 1=1
) 
SELECT 
    ss.c_customer_id,
    ss.customer_sales,
    ss.promo_name,
    ss.promo_usage
FROM 
    SalesSummary ss
ORDER BY 
    ss.customer_sales DESC
LIMIT 100;
