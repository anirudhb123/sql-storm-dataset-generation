
WITH address_info AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer
    JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_order_number, ws_item_sk
),
final_benchmark AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ai.full_address,
        SUM(si.total_sales) AS total_sales,
        COUNT(si.order_count) AS total_orders
    FROM 
        customer_info ci
    JOIN 
        address_info ai ON ci.c_customer_id = ai.ca_address_id
    JOIN 
        sales_info si ON ci.c_customer_id = si.ws_order_number
    GROUP BY 
        ci.full_name, ci.cd_gender, ci.cd_marital_status, ai.full_address
)
SELECT 
    fb.full_name,
    fb.cd_gender,
    fb.cd_marital_status,
    fb.full_address,
    fb.total_sales,
    fb.total_orders
FROM 
    final_benchmark fb
WHERE 
    fb.total_sales > (SELECT AVG(total_sales) FROM final_benchmark)
ORDER BY 
    fb.total_sales DESC;
