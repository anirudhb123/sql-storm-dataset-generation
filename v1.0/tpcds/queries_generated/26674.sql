
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_customer_sk) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Promotions AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT cs.cs_order_number) AS total_sales,
        SUM(cs.cs_ext_sales_price) AS total_revenue
    FROM 
        catalog_sales cs
    JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
),
SalesComparison AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        pi.promo_name,
        pi.total_sales,
        pi.total_revenue,
        ci.city_rank
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        Promotions pi ON ci.city_rank <= 5
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    promo_name,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_revenue, 0.00) AS total_revenue
FROM 
    SalesComparison
ORDER BY 
    total_revenue DESC, 
    full_name ASC
LIMIT 50;
