
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        d.d_date AS last_purchase_date,
        DATEDIFF(CURRENT_DATE, d.d_date) AS days_since_last_purchase
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date IS NOT NULL
),
AggregateData AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        AVG(days_since_last_purchase) AS avg_days_since_purchase
    FROM 
        CustomerData
    GROUP BY 
        ca_state
)
SELECT 
    ca_state,
    unique_customers,
    avg_days_since_purchase,
    CASE 
        WHEN avg_days_since_purchase < 30 THEN 'Frequent'
        WHEN avg_days_since_purchase BETWEEN 30 AND 90 THEN 'Moderate'
        ELSE 'Infrequent'
    END AS purchase_frequency
FROM 
    AggregateData
ORDER BY 
    unique_customers DESC;
