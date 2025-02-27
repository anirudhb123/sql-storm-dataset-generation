
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS last_purchase_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date >= '2023-01-01'
),
DistinctFullNames AS (
    SELECT DISTINCT 
        full_name
    FROM 
        RankedCustomers
    WHERE 
        purchase_rank = 1
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
)
SELECT 
    df.full_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip
FROM 
    DistinctFullNames df
JOIN 
    RankedCustomers rc ON df.full_name = rc.full_name
JOIN 
    AddressDetails ad ON rc.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = rc.c_customer_id)
WHERE 
    rc.purchase_rank = 1
ORDER BY 
    ad.ca_city, ad.ca_state, ad.ca_zip;
