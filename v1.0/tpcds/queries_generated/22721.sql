
WITH AddressWithReturns AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        SUM(COALESCE(sr.return_quantity, 0)) AS total_returned_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS unique_returns
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_city
),
CityReturnStats AS (
    SELECT 
        ca.ca_city,
        AVG(total_returned_qty) AS avg_returned_qty,
        MAX(unique_returns) AS max_unique_returns,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        AddressWithReturns a
    JOIN 
        customer c ON a.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
),
HighReturnCities AS (
    SELECT 
        cs.ca_city,
        cs.avg_returned_qty,
        cs.max_unique_returns,
        cs.customer_count
    FROM 
        CityReturnStats cs
    WHERE 
        cs.avg_returned_qty > (SELECT AVG(avg_returned_qty) FROM CityReturnStats)
        AND cs.customer_count > (SELECT COUNT(*) FROM customer) / 100
)
SELECT 
    ca.ca_city,
    CONCAT('City: ', ca.ca_city, ', Avg Returns: ', CAST(ROUND(hr.avg_returned_qty, 2) AS VARCHAR), 
           ', Max Unique Returns: ', hr.max_unique_returns, 
           ', Customer Count: ', hr.customer_count) AS return_summary
FROM 
    HighReturnCities hr
JOIN 
    customer_address ca ON hr.ca_city = ca.ca_city
ORDER BY 
    hr.max_unique_returns DESC, hr.avg_returned_qty DESC
LIMIT 10;
