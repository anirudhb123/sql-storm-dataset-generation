
WITH address_combinations AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country
    FROM 
        customer_address
),
income_range AS (
    SELECT 
        CONCAT('Income: $', ib_lower_bound, ' - $', ib_upper_bound) AS income_band,
        ib_income_band_sk
    FROM 
        income_band
),
customer_details AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
)
SELECT 
    ad.full_address,
    ad.ca_country,
    ir.income_band,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate
FROM 
    address_combinations AS ad
JOIN 
    income_range AS ir ON ir.ib_income_band_sk = (SELECT hd_income_band_sk FROM household_demographics WHERE hd_demo_sk = (SELECT c_current_hdemo_sk FROM customer WHERE c_current_addr_sk = ad.ca_address_sk LIMIT 1))
JOIN 
    customer_details AS cd ON cd.cd_purchase_estimate > 1000
ORDER BY 
    ad.ca_country, cd.full_name;
