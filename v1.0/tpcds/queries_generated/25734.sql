
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number != '' THEN CONCAT(' Suite ', ca_suite_number)
                   ELSE ''
               END) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS city_rank
    FROM 
        customer_address
),
PopularCities AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count
    FROM 
        RankedAddresses
    GROUP BY 
        ca_city
    HAVING 
        COUNT(*) > 10
),
DetailedAddresses AS (
    SELECT 
        R.full_address,
        C.c_first_name,
        C.c_last_name,
        C.c_email_address,
        P.p_promo_name
    FROM 
        RankedAddresses R
    JOIN 
        customer C ON C.c_current_addr_sk = R.ca_address_sk
    LEFT JOIN 
        web_sales WS ON WS.ws_ship_addr_sk = R.ca_address_sk
    LEFT JOIN 
        promotion P ON P.p_item_sk = WS.ws_item_sk
    WHERE 
        R.city_rank <= 5 AND
        R.full_address IS NOT NULL
)
SELECT 
    DA.full_address,
    DA.c_first_name,
    DA.c_last_name,
    DA.c_email_address,
    DA.p_promo_name,
    PC.address_count
FROM 
    DetailedAddresses DA
JOIN 
    PopularCities PC ON DA.full_address LIKE '%' || PC.ca_city || '%'
ORDER BY 
    PC.address_count DESC, DA.c_last_name, DA.c_first_name;
