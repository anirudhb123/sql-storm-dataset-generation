
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(CASE WHEN sr_return_quantity > 0 THEN sr_return_quantity ELSE 0 END) AS total_returned_quantity,
        SUM(CASE WHEN sr_return_amt > 0 THEN sr_return_amt ELSE 0 END) AS total_returned_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
PromotionDetails AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_id, p.p_start_date_sk, p.p_end_date_sk
)
SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cr.total_returned_quantity,
    cr.total_returned_amount,
    pd.total_sales_quantity,
    pd.total_sales_amount,
    (SELECT COUNT(*) 
     FROM customer_demographics cd 
     WHERE cd.cd_demo_sk = c.c_current_cdemo_sk AND cd.cd_gender = 'F') AS female_customers_count
FROM 
    CustomerReturns cr
JOIN 
    PromotionDetails pd ON cr.c_customer_sk = pd.p_promo_sk
WHERE 
    (cr.total_returned_quantity > 10 OR pd.total_sales_amount > 1000)
ORDER BY 
    cr.total_returned_quantity DESC, pd.total_sales_amount DESC
LIMIT 100;
