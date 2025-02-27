
WITH AddressDetails AS (
    SELECT 
        ca.c_city AS city, 
        ca.ca_state AS state, 
        COUNT(DISTINCT c.c_customer_id) AS customers_count,
        STRING_AGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, '; ') AS customer_names
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.c_city, ca.ca_state
),
SalesPerformance AS (
    SELECT 
        ws_bill_cdemo_sk AS demographic_sk, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    ad.city, 
    ad.state, 
    ad.customers_count, 
    ad.customer_names, 
    COALESCE(sp.total_sales, 0) AS total_sales_by_demographic
FROM 
    AddressDetails ad
LEFT JOIN 
    SalesPerformance sp ON ad.customers_count = sp.demographic_sk
WHERE 
    ad.customers_count > 0
ORDER BY 
    ad.city, ad.state;
