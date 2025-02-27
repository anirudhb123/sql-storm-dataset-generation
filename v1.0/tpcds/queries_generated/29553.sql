
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PromotionDetails AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        p.p_purchase_estimate
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
),
SalesSummary AS (
    SELECT 
        COUNT(*) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue,
        SUM(ws.ws_quantity) AS total_quantity,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ps.p_promo_name,
    ss.total_sales,
    ss.total_revenue,
    ss.total_quantity,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    PromotionDetails ps ON ss.total_sales > 0
ORDER BY 
    ss.total_revenue DESC 
LIMIT 
    100;
