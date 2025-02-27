
WITH AddressDetails AS (
    SELECT 
        ca.city AS address_city, 
        ca.state AS address_state, 
        CASE 
            WHEN LENGTH(ca.street_name) > 30 THEN CONCAT(SUBSTRING(ca.street_name, 1, 27), '...') 
            ELSE ca.street_name 
        END AS shortened_street_name,
        CONCAT(ca.street_number, ' ', 
               CASE 
                   WHEN ca.street_type IS NOT NULL THEN ca.street_type 
                   ELSE ''
               END, 
               ' ', 
               shortened_street_name) AS full_address
    FROM 
        customer_address ca
),
DemoCounts AS (
    SELECT 
        cd.gender, 
        cd.education_status, 
        COUNT(c.customer_sk) AS customer_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.gender, cd.education_status
),
HighBuyPotential AS (
    SELECT 
        hd.hd_income_band_sk, 
        hd.hd_buy_potential, 
        COUNT(hd.hd_demo_sk) AS high_potential_count
    FROM 
        household_demographics hd
    WHERE 
        hd.hd_buy_potential = 'High'
    GROUP BY 
        hd.hd_income_band_sk, hd.hd_buy_potential
)
SELECT 
    a.address_city, 
    a.full_address, 
    d.gender, 
    d.education_status, 
    d.customer_count, 
    h.hd_income_band_sk, 
    h.high_potential_count
FROM 
    AddressDetails a
JOIN 
    DemoCounts d ON d.customer_count > 1
JOIN 
    HighBuyPotential h ON h.high_potential_count > 5
WHERE 
    a.address_city IS NOT NULL
ORDER BY 
    a.address_city, d.gender;
