
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS order_count,
        LISTAGG(CAST(ws_item_sk AS TEXT), ', ') WITHIN GROUP (ORDER BY ws_item_sk) AS purchased_items
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
benchmark_report AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ss.total_spent,
        ss.order_count,
        ss.purchased_items
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ci.ca_state = 'CA' AND 
        ss.total_spent > 1000
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    total_spent,
    order_count,
    purchased_items
FROM 
    benchmark_report
ORDER BY 
    total_spent DESC
LIMIT 100;
