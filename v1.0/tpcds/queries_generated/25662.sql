
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        (SELECT COUNT(*) 
         FROM customer_demographics 
         WHERE cd_demo_sk = c.c_current_cdemo_sk AND cd_purchase_estimate > 5000) AS high_value_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_coupon_amt) AS total_coupons
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
combined_info AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        si.order_count,
        si.total_sales,
        si.total_coupons
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 10000 THEN 'High Spender'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category,
    OVERLAY(cd_education_status PLACING 'Graduate' FROM 1 FOR 1) AS modified_education_status
FROM 
    combined_info
ORDER BY 
    total_sales DESC, full_name;
