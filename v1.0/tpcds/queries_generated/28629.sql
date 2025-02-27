
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') AS streets
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
customer_summary AS (
    SELECT 
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        STRING_AGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') AS customer_names
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        gender
),
sales_summary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        STRING_AGG(DISTINCT w.w_warehouse_name, ', ') AS warehouses
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.cities,
    a.streets,
    c.gender,
    c.customer_count,
    c.total_dependents,
    c.customer_names,
    s.d_year,
    s.total_sales,
    s.warehouses
FROM 
    address_summary a
JOIN 
    customer_summary c ON a.unique_addresses > 0
JOIN 
    sales_summary s ON s.total_sales > 0
ORDER BY 
    a.ca_state, c.gender, s.d_year;
