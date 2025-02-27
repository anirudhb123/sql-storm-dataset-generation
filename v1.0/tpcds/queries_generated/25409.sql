
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        STRING_AGG(ca_street_name, '; ') AS street_names,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
customer_summary AS (
    SELECT 
        cd_gender,
        STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customers,
        SUM(cd_purchase_estimate) AS total_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        STRING_AGG(DISTINCT i.i_product_name, ', ') AS sold_products
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
    a.unique_addresses,
    a.street_names,
    c.cd_gender,
    c.customers,
    c.total_estimate,
    s.d_year,
    s.total_sales,
    s.total_quantity,
    s.sold_products
FROM 
    address_summary a
JOIN 
    customer_summary c ON c.customer_count > 0 
CROSS JOIN 
    sales_summary s
ORDER BY 
    a.ca_state, c.cd_gender, s.d_year;
