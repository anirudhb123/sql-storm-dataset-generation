
WITH customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT s.ss_ticket_number) AS total_purchases,
        SUM(s.ss_sales_price) AS total_spent,
        AVG(s.ss_sales_price) AS avg_spent_per_purchase,
        MAX(s.ss_sales_price) AS max_purchase,
        MIN(s.ss_sales_price) AS min_purchase
    FROM 
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL AND
        cd.cd_credit_rating IN ('Fair', 'Good', 'Excellent') 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
), ranked_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_purchases,
        cs.total_spent,
        cs.avg_spent_per_purchase,
        DENSE_RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS gender_ranking,
        CASE 
            WHEN cs.total_spent IS NULL THEN 0
            ELSE (cs.total_spent / NULLIF(cs.total_purchases, 0)) 
        END AS avg_purchase_value
    FROM 
        customer_stats cs
)
SELECT 
    r.c_customer_id,
    r.cd_gender,
    r.cd_marital_status,
    r.total_purchases,
    r.total_spent,
    r.avg_spent_per_purchase,
    r.gender_ranking,
    r.avg_purchase_value,
    CASE 
        WHEN r.gender_ranking = 1 THEN 'Top Performer'
        WHEN r.total_purchases > 5 THEN 'Regular Customer'
        ELSE 'Occasional Buyer'
    END AS customer_status,
    COALESCE(
        (SELECT MIN(ss_ext_discount_amt) 
         FROM store_sales 
         WHERE ss_customer_sk = c.c_customer_sk 
         AND ss_sold_date_sk IN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)), 
        0
    ) AS min_discount_last_year
FROM 
    ranked_customers r
ORDER BY 
    r.total_spent DESC NULLS LAST;
