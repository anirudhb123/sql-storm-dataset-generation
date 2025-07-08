
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PromotionsDetails AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk
),
StringManipulations AS (
    SELECT 
        c.full_name,
        CONCAT('Customer: ', c.full_name, ', Gender: ', c.cd_gender, ', State: ', c.ca_state) AS customer_info,
        CASE 
            WHEN c.cd_gender = 'F' THEN 'Female'
            WHEN c.cd_gender = 'M' THEN 'Male'
            ELSE 'Unknown'
        END AS gender_desc,
        PROM.p_promo_name,
        PROM.total_orders
    FROM 
        CustomerDetails c
    JOIN 
        PromotionsDetails PROM ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_promo_sk = PROM.p_promo_sk LIMIT 1)
),
FinalOutput AS (
    SELECT 
        customer_info,
        gender_desc,
        MAX(total_orders) OVER (PARTITION BY gender_desc) AS max_orders
    FROM 
        StringManipulations
)
SELECT 
    customer_info,
    gender_desc,
    max_orders
FROM 
    FinalOutput
WHERE 
    max_orders > 0
ORDER BY 
    gender_desc, max_orders DESC
LIMIT 
    100;
