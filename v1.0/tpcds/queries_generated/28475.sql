
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
monthly_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DATE_TRUNC('month', d.d_date) AS sales_month
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws_bill_customer_sk, sales_month
),
ranked_sales AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ms.sales_month,
        ms.total_sales,
        ROW_NUMBER() OVER (PARTITION BY ci.c_customer_id ORDER BY ms.total_sales DESC) AS sales_rank
    FROM 
        customer_info ci
    JOIN 
        monthly_sales ms ON ci.c_customer_id = ms.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    sales_month,
    total_sales
FROM 
    ranked_sales
WHERE 
    sales_rank = 1
ORDER BY 
    total_sales DESC
LIMIT 10;
