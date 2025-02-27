
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS spend_rank
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        SUM(cs.cs_net_paid_inc_tax) AS promo_total_sales
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    WHERE 
        p.p_start_date_sk < (
            SELECT DATEDIFF(DAY, MIN(d.d_date), MAX(d.d_date))
            FROM date_dim d
            WHERE d.d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim) 
            AND d.d_year = (SELECT MAX(d_year) FROM date_dim)
        )
    GROUP BY 
        p.p_promo_id
),
RankedPromotions AS (
    SELECT 
        promo_total_sales,
        DENSE_RANK() OVER (ORDER BY promo_total_sales DESC) AS promo_rank
    FROM 
        Promotions
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    cs.order_count,
    COALESCE(rp.promo_rank, 'No Promotion') AS promo_rank
FROM 
    CustomerSales cs
LEFT JOIN 
    RankedPromotions rp ON cs.spend_rank = rp.promo_rank
WHERE 
    cs.total_spent IS NOT NULL 
    AND (cs.order_count >= 3 OR cs.total_spent > 1000)
ORDER BY 
    cs.total_spent DESC, cs.c_last_name ASC;
