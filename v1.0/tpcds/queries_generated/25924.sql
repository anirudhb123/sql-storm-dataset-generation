
WITH filtered_customer AS (
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
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 5000
),
aggregated_sales AS (
    SELECT
        c.c_customer_sk,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_net_paid) AS total_amount_spent
    FROM 
        store_sales ss
    JOIN 
        filtered_customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_summary AS (
    SELECT 
        fc.full_name,
        fc.ca_city,
        fc.ca_state,
        COALESCE(asales.total_transactions, 0) AS total_transactions,
        COALESCE(asales.total_amount_spent, 0) AS total_amount_spent
    FROM 
        filtered_customer fc
    LEFT JOIN 
        aggregated_sales asales ON fc.c_customer_sk = asales.c_customer_sk
)

SELECT 
    CONCAT('Customer: ', cs.full_name, ' | Location: ', cs.ca_city, ', ', cs.ca_state, 
           ' | Transactions: ', cs.total_transactions, 
           ' | Total Spent: $', FORMAT(cs.total_amount_spent, 2)) AS customer_benchmark_info
FROM 
    customer_summary cs
ORDER BY 
    cs.total_amount_spent DESC 
LIMIT 10;
