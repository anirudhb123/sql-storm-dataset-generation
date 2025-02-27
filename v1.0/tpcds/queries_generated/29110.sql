
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city) AS complete_address
    FROM customer_address
),
gender_stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        STRING_AGG(ca.complete_address, '; ') AS addresses
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN address_parts ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY cd_gender
),
income_stats AS (
    SELECT 
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS total_customers,
        STRING_AGG(ca.complete_address, '; ') AS addresses
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN address_parts ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    gs.cd_gender,
    gs.total_customers AS gender_customer_count,
    ISNULL(gs.addresses, 'No addresses available') AS gender_addresses,
    is.ib_lower_bound,
    is.ib_upper_bound,
    is.total_customers AS income_customer_count,
    ISNULL(is.addresses, 'No addresses available') AS income_addresses
FROM gender_stats gs
FULL OUTER JOIN income_stats is ON gs.total_customers = is.total_customers
ORDER BY gs.cd_gender, is.ib_lower_bound;
