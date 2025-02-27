
WITH address_summary AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_address_count,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city
),
demo_analysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        COUNT(*) AS customer_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
sales_analysis AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        STRING_AGG(DISTINCT CONCAT(ws_order_number, ':', ws_net_profit), ', ') AS order_details
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.ca_city,
    a.unique_address_count,
    a.full_address_list,
    d.cd_gender,
    d.cd_marital_status,
    d.total_purchase_estimate,
    d.customer_count,
    s.d_year,
    s.total_sales,
    s.total_orders,
    s.order_details
FROM 
    address_summary a
JOIN 
    demo_analysis d ON a.ca_city IN (SELECT DISTINCT ca_city FROM customer_address WHERE ca_state = 'CA') 
JOIN 
    sales_analysis s ON s.total_sales > 10000
ORDER BY 
    a.ca_state, a.ca_city, d.cd_gender;
