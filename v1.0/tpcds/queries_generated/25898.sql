
WITH formatted_addresses AS (
    SELECT 
        ca_city || ', ' || ca_state || ' ' || ca_zip AS full_address, 
        ca_address_sk,
        ca_street_name,
        ca_street_number,
        ca_suite_number,
        ca_country
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
        MAX(CONCAT(ci.full_name, ' (', ci.cd_gender, ')')) AS sample_customers
    FROM 
        formatted_addresses ca
    JOIN 
        customer_info ci ON ci.c_customer_sk IN (
            SELECT s.ws_bill_customer_sk FROM sales_summary s
            WHERE s.total_orders > 5
        )
    GROUP BY 
        ca.ca_address_sk
)
SELECT 
    fa.full_address,
    asu.customer_count,
    asu.sample_customers,
    ss.total_orders,
    ss.total_spent
FROM 
    formatted_addresses fa
JOIN 
    address_summary asu ON fa.ca_address_sk = asu.ca_address_sk
JOIN 
    sales_summary ss ON ss.ws_bill_customer_sk IN (
        SELECT c.c_customer_sk FROM customer_info c
        WHERE c.c_current_addr_sk = asu.ca_address_sk
    )
ORDER BY 
    ss.total_spent DESC
LIMIT 10;
