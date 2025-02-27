
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
PromotionsImpact AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS promo_used_count,
        SUM(ss.ss_net_paid) AS total_promo_sales
    FROM 
        store_sales ss
    JOIN 
        promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        p.p_promo_name
),
EngagementStats AS (
    SELECT 
        cd.cd_gender,
        AVG(cp.total_spent) AS avg_spent,
        SUM(p.promo_used_count) AS total_promotions_used
    FROM 
        CustomerPurchases cp
    JOIN 
        customer_demographics cd ON cp.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    es.cd_gender,
    es.avg_spent,
    es.total_promotions_used,
    COALESCE(pi.total_promo_sales, 0) AS promo_sales_total
FROM 
    EngagementStats es
LEFT JOIN 
    (SELECT 
         p.promo_name, 
         SUM(total_promo_sales) AS total_promo_sales 
     FROM 
         PromotionsImpact p 
     GROUP BY 
         p.promo_name) pi ON pi.promo_name = 'Special Discount'
ORDER BY 
    es.cd_gender;
