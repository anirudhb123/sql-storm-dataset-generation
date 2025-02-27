
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date) AS purchase_rank
    FROM 
        customer c 
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
FrequentCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.full_name,
        COUNT(ss.ticket_number) AS total_sales,
        SUM(ss.ss_sales_price) AS total_spent
    FROM 
        RankedCustomers rc 
    JOIN 
        store_sales ss ON rc.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        rc.c_customer_sk, rc.full_name
    HAVING 
        COUNT(ss.ticket_number) > 5
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_city) AS address_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    fc.full_name,
    fc.total_sales,
    fc.total_spent,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    FrequentCustomers fc 
JOIN 
    CustomerAddresses ca ON fc.c_customer_sk = ca.c_customer_sk
WHERE 
    ca.address_rank = 1
ORDER BY 
    fc.total_spent DESC
LIMIT 10;
