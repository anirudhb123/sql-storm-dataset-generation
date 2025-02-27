
WITH CustomerDetails AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM customer c 
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
AddressStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS customer_count,
        STRING_AGG(CONCAT(first_name, ' ', last_name), ', ') AS customer_names
    FROM CustomerDetails
    GROUP BY ca_city, ca_state
),
GenderIncomeStats AS (
    SELECT 
        cd_gender,
        hd_income_band_sk,
        COUNT(*) AS count
    FROM CustomerDetails cd
    JOIN household_demographics hd ON cd.c_customer_sk = hd.hd_demo_sk
    GROUP BY cd_gender, hd_income_band_sk
),
FinalStats AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.customer_count,
        a.customer_names,
        g.cd_gender,
        g.hd_income_band_sk,
        g.count
    FROM AddressStats a
    JOIN GenderIncomeStats g ON a.customer_count > 10
)
SELECT 
    city,
    state,
    customer_count,
    customer_names,
    cd_gender,
    hd_income_band_sk
FROM FinalStats
ORDER BY ca_city, ca_state, cd_gender, hd_income_band_sk;
