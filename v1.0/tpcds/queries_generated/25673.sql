
WITH address_counts AS (
    SELECT 
        ca_state,
        LOWER(ca_city) AS city_lower,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state, LOWER(ca_city)
),
demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate <= 100 THEN 'Low'
            WHEN cd_purchase_estimate <= 500 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer_demographics
),
sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    a.ca_state,
    a.city_lower,
    d.cd_gender,
    d.purchase_category,
    s.total_orders,
    s.total_sales,
    s.total_quantity,
    CONCAT(a.city_lower, ', ', a.ca_state) AS location_summary
FROM 
    address_counts a
JOIN 
    demographics d ON d.cd_demo_sk = a.ca_state
LEFT JOIN 
    sales_summary s ON s.ws_ship_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
ORDER BY 
    a.ca_state, a.city_lower, d.cd_gender;
