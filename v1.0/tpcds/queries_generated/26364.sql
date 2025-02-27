
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        ca.city,
        ca.state,
        SUBSTRING(ca.zip FROM 1 FOR 5) AS zip_prefix,
        cd.education_status,
        cd.marital_status,
        cd.purchase_estimate,
        cd.credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
ranked_sales AS (
    SELECT 
        ci.full_name,
        ci.gender,
        ci.city,
        ci.state,
        ci.zip_prefix,
        ci.education_status,
        ci.marital_status,
        ci.purchase_estimate,
        ci.credit_rating,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        RANK() OVER (ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_id = ss.bill_customer_sk
)
SELECT 
    *
FROM 
    ranked_sales
WHERE 
    sales_rank <= 100
ORDER BY 
    total_sales DESC, full_name;
