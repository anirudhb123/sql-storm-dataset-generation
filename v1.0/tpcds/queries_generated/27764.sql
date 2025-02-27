
WITH address_summary AS (
    SELECT 
        ca.city,
        ca.state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
        STRING_AGG(DISTINCT ca.ca_street_name || ' ' || ca.ca_street_type, ', ') AS street_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city, ca.state
),
income_summary AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count,
        STRING_AGG(DISTINCT cd.cd_credit_rating, ', ') AS credit_ratings
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    a.city,
    a.state,
    a.customer_count,
    a.male_count,
    a.female_count,
    a.average_purchase_estimate,
    a.street_names,
    i.demographic_count,
    i.credit_ratings
FROM 
    address_summary a
JOIN 
    income_summary i ON a.city = (SELECT city FROM customer_address WHERE ca_address_sk = c_current_addr_sk LIMIT 1)
ORDER BY 
    a.customer_count DESC, a.city;
