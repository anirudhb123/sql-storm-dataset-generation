
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_bill_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
aggregated_sales AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        sales_data
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        aggregated_sales
)
SELECT 
    ci.full_name,
    ci.full_address,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Performer'
        ELSE 'Regular Customer'
    END AS customer_rank,
    rs.total_quantity,
    rs.total_sales
FROM 
    customer_info ci
JOIN 
    ranked_sales rs ON ci.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = rs.cd_gender LIMIT 1)
WHERE 
    rs.total_sales > 1000
ORDER BY 
    rs.total_sales DESC;
