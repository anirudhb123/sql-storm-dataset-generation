
WITH categorized_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 2000 THEN 'Low Value'
            WHEN cd.cd_purchase_estimate BETWEEN 2000 AND 5000 THEN 'Medium Value'
            ELSE 'High Value'
        END AS customer_value_category,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
promotional_items AS (
    SELECT 
        p.p_promo_name,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        p.p_start_date_sk,
        p.p_end_date_sk
    FROM
        promotion p
    JOIN
        item i ON p.p_item_sk = i.i_item_sk
    WHERE
        p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d) 
        AND p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d)
),
customer_promotions AS (
    SELECT 
        cc.full_name,
        pi.p_promo_name,
        pi.i_product_name,
        pi.i_current_price
    FROM
        categorized_customers cc
    JOIN
        web_sales ws ON cc.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        promotional_items pi ON ws.ws_promo_sk = pi.p_promo_sk
)
SELECT 
    cp.full_name,
    cp.p_promo_name,
    cp.i_product_name,
    COUNT(cp.i_product_name) AS promotion_count,
    AVG(cp.i_current_price) AS avg_price
FROM
    customer_promotions cp
GROUP BY
    cp.full_name,
    cp.p_promo_name,
    cp.i_product_name
ORDER BY
    promotion_count DESC,
    avg_price DESC
LIMIT 10;
