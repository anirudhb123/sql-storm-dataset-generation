
WITH AddressCityCount AS (
    SELECT 
        ca_city,
        COUNT(*) AS city_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
MaxCityCount AS (
    SELECT 
        MAX(city_count) AS max_count
    FROM 
        AddressCityCount
),
FrequentCities AS (
    SELECT 
        ca_city,
        city_count
    FROM 
        AddressCityCount
    WHERE 
        city_count = (SELECT max_count FROM MaxCityCount)
),
CustomerJoin AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ac.ca_city
    FROM 
        customer c
    JOIN 
        customer_address ac ON c.c_current_addr_sk = ac.ca_address_sk
    WHERE 
        ac.ca_city IN (SELECT ca_city FROM FrequentCities)
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    c.ca_city,
    COUNT(ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid) AS total_spent
FROM 
    CustomerJoin c
LEFT JOIN 
    web_sales ws ON c.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    customer_name, c.ca_city
ORDER BY 
    total_spent DESC
LIMIT 10;
