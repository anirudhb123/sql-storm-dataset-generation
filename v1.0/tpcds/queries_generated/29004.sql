
WITH CustomerPromotions AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        CASE 
            WHEN p.p_channel_email = 'Y' THEN 'Email'
            WHEN p.p_channel_dmail = 'Y' THEN 'Direct Mail'
            WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
            ELSE 'Other'
        END AS promotion_channel,
        DATEDIFF(DATE(d.d_date), DATE(d2.d_date)) AS days_between
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        date_dim d2 ON c.c_first_shipto_date_sk = d2.d_date_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
        AND DATEDIFF(DATE(d.d_date), DATE(d2.d_date)) BETWEEN 30 AND 365
    ORDER BY 
        customer_name, p.p_start_date_sk
)
SELECT 
    promotion_channel, 
    COUNT(*) AS total_promotions, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers
FROM 
    CustomerPromotions
GROUP BY 
    promotion_channel
HAVING 
    total_promotions > 5
ORDER BY 
    total_promotions DESC;
