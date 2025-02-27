
WITH AddressParts AS (
    SELECT 
        ca_address_sk, 
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerNames AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS FullName,
        c_email_address
    FROM customer
),
SalesSummary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS TotalNetProfit
    FROM store_sales
    GROUP BY ss_store_sk
)
SELECT 
    a.FullAddress,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    CONCAT(c.FullName, ' <', c.c_email_address, '>') AS CustomerContact,
    s.TotalNetProfit
FROM 
    AddressParts a
JOIN 
    CustomerNames c ON c.c_customer_sk = (
        SELECT ss_customer_sk 
        FROM store_sales 
        WHERE ss_store_sk = (
            SELECT ss_store_sk 
            FROM store 
            WHERE s_city = a.ca_city AND s_state = a.ca_state LIMIT 1
        ) LIMIT 1
    )
JOIN 
    SalesSummary s ON s.ss_store_sk = (
        SELECT ss_store_sk 
        FROM store 
        WHERE s_city = a.ca_city AND s_state = a.ca_state LIMIT 1
    )
WHERE 
    a.FullAddress LIKE '%Main%'
ORDER BY 
    s.TotalNetProfit DESC;
