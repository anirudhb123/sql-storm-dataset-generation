
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        count(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate > 1000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate,
        cd.cd_credit_rating, cd.cd_dep_count, cd.cd_dep_employed_count,
        cd.cd_dep_college_count, ca.ca_city, ca.ca_state
),
OrderStats AS (
    SELECT 
        c.ca_city,
        c.ca_state,
        COUNT(ci.c_customer_sk) AS customer_count,
        AVG(ci.total_spent) AS avg_spent,
        SUM(ci.total_orders) AS total_orders
    FROM 
        CustomerInfo ci
    JOIN 
        customer_address c ON ci.c_customer_sk = c.ca_address_sk
    GROUP BY 
        c.ca_city, c.ca_state
)
SELECT 
    city,
    state,
    customer_count,
    avg_spent,
    total_orders,
    RANK() OVER (ORDER BY customer_count DESC) AS rank_by_customers,
    RANK() OVER (ORDER BY avg_spent DESC) AS rank_by_spending
FROM 
    OrderStats
WHERE 
    customer_count > 10
ORDER BY 
    customer_count DESC, total_orders DESC;
