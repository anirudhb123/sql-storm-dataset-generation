
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS average_sales
    FROM 
        sales_info
),
result AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(si.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(si.total_sales, 0) > asv.average_sales THEN 'Above Average'
            ELSE 'Below Average'
        END AS sales_category
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
    CROSS JOIN 
        avg_sales asv
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    sales_category
FROM 
    result
ORDER BY 
    total_sales DESC;
