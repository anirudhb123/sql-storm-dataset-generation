
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PromotionalStats AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
),
FilteredInfo AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_zip,
        ps.promo_name,
        ps.total_sales,
        ps.total_revenue
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        PromotionalStats ps ON ci.ca_city = 'San Francisco' AND ps.total_sales > 10
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_zip,
    COALESCE(promo_name, 'No Promotions') AS promo_name,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_revenue, 0.00) AS total_revenue
FROM 
    FilteredInfo
ORDER BY 
    total_revenue DESC
LIMIT 100;
