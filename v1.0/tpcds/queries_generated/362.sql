
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
PromotionDetails AS (
    SELECT 
        p.promo_id,
        p.promo_name,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.promo_id, p.promo_name
)
SELECT 
    hvc.first_name,
    hvc.last_name,
    hvc.total_sales,
    hvc.order_count,
    pd.promo_name,
    pd.promo_sales
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    PromotionDetails pd ON hvc.sales_rank <= 10 AND hvc.total_sales > 2000
WHERE 
    hvc.total_sales IS NOT NULL
ORDER BY 
    hvc.total_sales DESC, hvc.order_count DESC;
