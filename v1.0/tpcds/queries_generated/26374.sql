
WITH tmp_customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_marital_status,
        cd.cd_gender,
        LENGTH(c.c_email_address) AS email_length,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
tmp_sales AS (
    SELECT 
        s.ss_customer_sk,
        SUM(s.ss_net_paid_inc_tax) AS total_spent,
        COUNT(s.ss_ticket_number) AS transaction_count
    FROM 
        store_sales s 
    GROUP BY 
        s.ss_customer_sk
),
final_report AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.marital_status,
        ci.gender,
        ci.email_length,
        ci.purchase_estimate,
        COALESCE(ts.total_spent, 0) AS total_spent,
        COALESCE(ts.transaction_count, 0) AS transaction_count,
        ci.city_rank
    FROM 
        tmp_customer_info ci
    LEFT JOIN 
        tmp_sales ts ON ci.c_customer_sk = ts.ss_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    final_report
WHERE 
    city_rank <= 10
ORDER BY 
    ca_city, total_spent DESC;
