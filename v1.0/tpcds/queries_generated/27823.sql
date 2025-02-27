
WITH address_data AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        UPPER(ca_city) AS upper_city
    FROM 
        customer_address
),
customer_data AS (
    SELECT 
        c_first_name,
        c_last_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr. ' || c_first_name
            ELSE 'Ms. ' || c_first_name
        END AS salutation
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.web_site_id,
        ws_ext_sales_price,
        d_year,
        d_month_seq,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
        ad.full_address,
        ad.upper_city
    FROM 
        web_sales ws
    JOIN 
        customer_data c ON ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        address_data ad ON ws_bill_addr_sk = ad.ca_address_sk
    JOIN 
        date_dim dd ON ws_sold_date_sk = d_date_sk
)
SELECT 
    web_site_id,
    AVG(ws_ext_sales_price) AS avg_sales_price,
    COUNT(*) AS total_sales,
    COUNT(DISTINCT full_customer_name) AS unique_customers,
    upper_city
FROM 
    sales_data
GROUP BY 
    web_site_id, upper_city
HAVING 
    AVG(ws_ext_sales_price) > 50
ORDER BY 
    avg_sales_price DESC, unique_customers DESC;
