
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        COALESCE(cd.cd_education_status, 'N/A') AS education_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(ca.ca_city, 'Unknown') AS city,
        COALESCE(ca.ca_state, 'XX') AS state,
        COALESCE(ca.ca_country, 'Unknown') AS country
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        w.web_site_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        w.web_site_id
),
Promotions AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS orders_with_promotion
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    ci.full_name,
    ci.gender,
    ci.marital_status,
    ci.education_status,
    ci.purchase_estimate,
    CONCAT(sd.total_orders, ' (', sd.total_sales, ')') AS sales_info,
    JSON_AGG(JSON_BUILD_OBJECT('promo_name', pr.p_promo_name, 'orders_with_promo', pr.orders_with_promotion)) AS promotions
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.city = sd.web_site_id
LEFT JOIN 
    Promotions pr ON pr.orders_with_promotion > 0
GROUP BY 
    ci.full_name, ci.gender, ci.marital_status, ci.education_status, ci.purchase_estimate, sd.total_orders, sd.total_sales
ORDER BY 
    ci.purchase_estimate DESC, ci.full_name;
