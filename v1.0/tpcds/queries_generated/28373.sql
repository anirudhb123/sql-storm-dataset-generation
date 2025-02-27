
WITH customer_information AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_address_id,
        (CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other' 
        END) AS marital_status_desc,
        (SELECT COUNT(*) FROM customer_demographics WHERE cd_income_band_sk = hd.hd_income_band_sk) AS income_band_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        ca.ca_city LIKE '%Springfield%'
        AND cd.cd_education_status IN ('Bachelor', 'Masters')
),
address_summary AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        STRING_AGG(DISTINCT ca.ca_zip, ', ') AS zip_codes
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_city, ca.ca_state
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.marital_status_desc,
    asum.city,
    asum.state,
    asum.zip_codes,
    ss.total_sales,
    ss.total_orders
FROM 
    customer_information ci
LEFT JOIN 
    address_summary asum ON ci.ca_city = asum.ca_city AND ci.ca_state = asum.ca_state
LEFT JOIN 
    sales_summary ss ON ci.c_customer_id = ss.ws_bill_customer_sk
ORDER BY 
    ci.full_name;
