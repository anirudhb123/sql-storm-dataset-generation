
WITH address_summary AS (
    SELECT 
        ca_state, 
        ca_city, 
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') AS street_info
    FROM 
        customer_address
    GROUP BY 
        ca_state, 
        ca_city
),
demographics_summary AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS demographic_count, 
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_statuses,
        STRING_AGG(DISTINCT cd_credit_rating, ', ') AS credit_ratings
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_info AS (
    SELECT 
        d.d_year, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        STRING_AGG(DISTINCT i_product_name, ', ') AS sold_products
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        d.d_year
)
SELECT 
    a.ca_state, 
    a.ca_city, 
    a.address_count, 
    a.street_info, 
    d.cd_gender, 
    d.demographic_count, 
    d.education_statuses, 
    d.credit_ratings, 
    s.d_year, 
    s.total_sales,
    s.total_orders,
    s.sold_products
FROM 
    address_summary a
JOIN 
    demographics_summary d ON a.ca_city = 'Seattle' AND d.cd_gender = 'F'
JOIN 
    sales_info s ON s.d_year = 2023
WHERE 
    a.address_count > 50
ORDER BY 
    a.address_count DESC, 
    s.total_sales DESC;
