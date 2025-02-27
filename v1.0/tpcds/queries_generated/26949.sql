
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
RankedAddresses AS (
    SELECT 
        a.full_address,
        d.full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.ib_lower_bound,
        d.ib_upper_bound,
        RANK() OVER (PARTITION BY d.cd_gender ORDER BY d.ib_lower_bound) AS income_rank
    FROM 
        AddressParts a
    JOIN 
        Demographics d ON d.c_customer_sk = a.ca_address_sk
)
SELECT 
    ra.full_address,
    ra.full_name,
    ra.cd_gender,
    ra.cd_marital_status,
    ra.ib_lower_bound,
    ra.ib_upper_bound,
    ra.income_rank
FROM 
    RankedAddresses ra
WHERE 
    ra.income_rank <= 5
ORDER BY 
    ra.cd_gender, 
    ra.ib_lower_bound;
