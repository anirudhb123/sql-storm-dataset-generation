
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        AVG(ss.ss_ext_sales_price) AS avg_sales_per_transaction,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_sales_amount
    FROM 
        customer_summary cs
    WHERE 
        cs.total_sales_amount > (SELECT AVG(total_sales_amount) FROM customer_summary)
),
promotions_summary AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        SUM(cs.total_sales_amount) AS total_sales_amount_promo
    FROM 
        high_value_customers hvc
    JOIN 
        web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
),
final_summary AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales_amount,
        COALESCE(ps.total_sales_amount_promo, 0) AS total_promo_sales
    FROM 
        high_value_customers cs
    LEFT JOIN 
        promotions_summary ps ON cs.c_customer_sk = ps.c_customer_sk
)
SELECT 
    fs.c_first_name,
    fs.c_last_name,
    fs.total_sales_amount,
    fs.total_promo_sales,
    CASE 
        WHEN fs.total_promo_sales > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS used_promotions,
    CASE 
        WHEN fs.total_sales_amount IS NULL THEN 'N/A'
        ELSE ROUND(fs.total_sales_amount, 2)
    END AS rounded_sales_amount
FROM 
    final_summary fs
ORDER BY 
    fs.total_sales_amount DESC
LIMIT 100;
