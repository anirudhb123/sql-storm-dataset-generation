
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_orders, 0) AS total_orders,
        CASE 
            WHEN ss.total_sales > 1000 THEN 'High Value'
            WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
        AND (ca.ca_city IS NOT NULL OR ca.ca_state IS NOT NULL)
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS customer_rank
    FROM 
        customer_analysis
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.ca_city,
    t.total_sales,
    t.customer_value
FROM 
    top_customers t
WHERE 
    t.customer_rank <= 100
UNION ALL
SELECT 
    'N/A' AS c_customer_sk,
    'Total' AS c_first_name,
    NULL AS c_last_name,
    NULL AS ca_city,
    SUM(total_sales) AS total_sales,
    NULL AS customer_value
FROM 
    customer_analysis
HAVING 
    SUM(total_sales) > 10000
ORDER BY 
    total_sales DESC;
