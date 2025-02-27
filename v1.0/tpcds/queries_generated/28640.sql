
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
), 
AddressAggregate AS (
    SELECT 
        ca_state,
        ca_city,
        STRING_AGG(ca_street_name, ', ') AS street_names,
        COUNT(*) AS address_count
    FROM 
        RankedAddresses
    WHERE 
        address_rank <= 5
    GROUP BY 
        ca_state, ca_city
) 
SELECT 
    a.ca_state,
    a.ca_city,
    a.street_names,
    a.address_count,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq
FROM 
    AddressAggregate a
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales ws)
WHERE 
    a.address_count > 0
ORDER BY 
    a.ca_state, a.ca_city;
