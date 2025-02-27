
WITH RECURSIVE AddressHierarchy AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        ca_street_number,
        ca_street_name,
        ca_city,
        ca_state,
        ca_country,
        1 AS level
    FROM 
        customer_address
    WHERE 
        ca_state IS NOT NULL
    UNION ALL
    SELECT 
        a.ca_address_sk,
        a.ca_address_id,
        a.ca_street_number,
        a.ca_street_name,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        ah.level + 1
    FROM 
        customer_address a
    INNER JOIN AddressHierarchy ah ON a.ca_state = ah.ca_state
    WHERE 
        ah.level < 5
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        MAX(d.d_year) - MIN(d.d_year) AS customer_age_range,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk
),
SalesData AS (
    SELECT 
        SUM(ws.ws_sales_price) AS total_sales,
        ws.ws_bill_customer_sk,
        CASE 
            WHEN SUM(ws.ws_sales_price) > 1000 THEN 'High Value'
            WHEN SUM(ws.ws_sales_price) IS NULL THEN 'No Sales'
            ELSE 'Regular'
        END AS customer_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ah.ca_city,
    ah.ca_country,
    cs.unique_customers,
    sd.total_sales,
    sd.customer_value
FROM 
    AddressHierarchy ah
LEFT JOIN 
    CustomerStats cs ON ah.ca_address_sk = cs.c_customer_sk
FULL OUTER JOIN 
    SalesData sd ON cs.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    (ah.ca_state IS NOT NULL OR ah.ca_city LIKE 'New%')
    AND (sd.customer_value = 'High Value' OR cs.customer_age_range > 5)
ORDER BY 
    COALESCE(sd.total_sales, 0) DESC, 
    ah.ca_city ASC;
