
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
active_customers AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.full_address
    FROM customer_info ci
    WHERE ci.rnk <= 5 AND ci.cd_marital_status = 'M'
),
purchase_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ac.full_name,
    ac.cd_gender,
    ac.cd_marital_status,
    ac.cd_education_status,
    ac.full_address,
    COALESCE(ps.total_orders, 0) AS total_orders,
    COALESCE(ps.total_spent, 0) AS total_spent
FROM active_customers ac
LEFT JOIN purchase_summary ps ON ac.full_name = (SELECT CONCAT(c.c_first_name, ' ', c.c_last_name) FROM customer c WHERE c.c_customer_sk = ps.c_customer_sk)
ORDER BY ac.cd_gender, ac.total_orders DESC, ac.full_name;
