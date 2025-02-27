
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
), 
sales_by_region AS (
    SELECT 
        ai.ca_city,
        ai.ca_state,
        SUM(ss.total_net_profit) AS total_sales_profit
    FROM 
        address_info ai
    JOIN 
        sales_summary ss ON ai.customer_count > 0
    GROUP BY 
        ai.ca_city, ai.ca_state
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ab.ca_city,
    ab.ca_state,
    sb.total_sales_profit,
    CASE 
        WHEN ci.cd_purchase_estimate > 10000 THEN 'High Value Customer'
        WHEN ci.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value,
    COALESCE(NULLIF(sb.total_sales_profit, 0), 'No Sales') AS sales_status
FROM 
    customer_info ci
JOIN 
    address_info ab ON ci.c_customer_sk = ab.customer_count
LEFT JOIN 
    sales_by_region sb ON ab.ca_city = sb.ca_city AND ab.ca_state = sb.ca_state
WHERE 
    ci.gender_rank = 1 AND ab.customer_count > 0
ORDER BY 
    sb.total_sales_profit DESC
LIMIT 50;
