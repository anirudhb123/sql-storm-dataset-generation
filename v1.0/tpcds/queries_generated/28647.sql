
WITH AddressInfo AS (
    SELECT
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length
    FROM customer_address
    WHERE ca_country = 'USA'
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.street_name_length
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressInfo ad ON c.c_current_addr_sk = ad.ca_address_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
OrderStatistics AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM web_sales ws
    JOIN CustomerDetails c ON ws.ws_bill_customer_sk = c.c_customer_id
    GROUP BY c.customer_id
)
SELECT
    customer_id,
    full_name,
    total_orders,
    total_spent,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value' 
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM OrderStatistics o
JOIN CustomerDetails c ON o.customer_id = c.c_customer_id
ORDER BY total_spent DESC;
