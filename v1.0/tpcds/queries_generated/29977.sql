
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk, 
        ca_street_number, 
        ca_street_name, 
        ca_city, 
        ca_state, 
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_street_name) AS addr_rank
    FROM 
        customer_address
),
CityProfile AS (
    SELECT 
        ca.city AS city_name, 
        COUNT(*) AS address_count, 
        STRING_AGG(DISTINCT ca_state, ', ') AS states 
    FROM 
        RankedAddresses ca 
    WHERE 
        ca.addr_rank <= 5 
    GROUP BY 
        ca.city
),
CustomerAgeGender AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        EXTRACT(YEAR FROM AGE(DATE(pd.p_start_date_sk))) AS age
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    JOIN 
        promotion pd ON c.c_customer_sk = pd.p_promo_sk
)
SELECT 
    cp.city_name, 
    cp.address_count, 
    cp.states, 
    COUNT(c.agender) as gender_count,
    AVG(c.age) as average_age
FROM 
    CityProfile cp 
LEFT JOIN 
    CustomerAgeGender c ON cp.city_name = c.c_first_name
WHERE 
    c.agender = 'M'
GROUP BY 
    cp.city_name, 
    cp.address_count, 
    cp.states
ORDER BY 
    cp.address_count DESC
LIMIT 10;
