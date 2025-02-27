
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CONCAT(c.c_email_address, ' (', c.c_login, ')') AS contact_info
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
merged_data AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.contact_info,
        ss.total_orders,
        ss.total_sales,
        ss.avg_profit
    FROM 
        customer_details cd
    LEFT JOIN 
        sales_summary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    md.full_name,
    md.ca_city,
    md.ca_state,
    md.cd_gender,
    md.cd_marital_status,
    md.total_orders,
    md.total_sales,
    md.avg_profit,
    CASE
        WHEN md.total_sales IS NULL THEN 'No Sales'
        WHEN md.total_sales < 1000 THEN 'Low Value Customer'
        WHEN md.total_sales BETWEEN 1000 AND 5000 THEN 'Moderate Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_category
FROM 
    merged_data md
ORDER BY 
    md.total_sales DESC;
