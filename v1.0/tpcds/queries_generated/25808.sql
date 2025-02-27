
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_sales AS (
    SELECT
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        si.total_net_profit,
        si.order_count
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_net_profit,
    order_count,
    CASE 
        WHEN order_count > 10 THEN 'Frequent Shopper'
        WHEN order_count BETWEEN 5 AND 10 THEN 'Regular Shopper'
        ELSE 'Occasional Shopper'
    END AS shopper_category
FROM 
    customer_sales
WHERE 
    ca_state = 'CA'
ORDER BY 
    total_net_profit DESC
LIMIT 100;
