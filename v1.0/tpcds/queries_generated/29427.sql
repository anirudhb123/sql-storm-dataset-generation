
WITH CustomerAddresses AS (
    SELECT 
        ca_address_id, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip 
    FROM customer_address
),
AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(full_address, '; ') AS all_addresses
    FROM CustomerAddresses
    GROUP BY ca_state
),
IncomeCategory AS (
    SELECT 
        hd_income_band_sk, 
        CASE 
            WHEN hd_income_band_sk = 1 THEN 'Low Income'
            WHEN hd_income_band_sk = 2 THEN 'Middle Income'
            WHEN hd_income_band_sk = 3 THEN 'High Income'
            ELSE 'Unknown' 
        END AS income_bracket
    FROM household_demographics
)
SELECT 
    a.ca_state, 
    i.income_bracket,
    a.address_count, 
    a.all_addresses
FROM AddressStats a
JOIN IncomeCategory i ON a.address_count > 100
ORDER BY a.ca_state, i.income_bracket;
