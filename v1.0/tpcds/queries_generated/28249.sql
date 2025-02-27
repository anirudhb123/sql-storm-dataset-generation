
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_country = 'USA'
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON rc.c_customer_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON rc.c_customer_sk = cd.cd_demo_sk
    WHERE 
        rc.rnk <= 10
    GROUP BY 
        rc.c_customer_sk, rc.full_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    *,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    CustomerDetails
ORDER BY 
    customer_value_segment DESC, total_spent DESC;
