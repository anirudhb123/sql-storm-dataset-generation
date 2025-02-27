
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk DESC) AS address_rank
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        full_address, 
        ca_city, 
        ca_state, 
        address_rank
    FROM 
        RankedAddresses
    WHERE 
        address_rank <= 10
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY 
        ws.web_site_id
)
SELECT 
    fa.full_address,
    fa.ca_city,
    fa.ca_state,
    sd.web_site_id,
    sd.total_sales
FROM 
    FilteredAddresses fa
LEFT JOIN 
    SalesData sd ON fa.ca_city = sd.web_site_id
WHERE 
    fa.ca_state = 'CA'
ORDER BY 
    sd.total_sales DESC;
