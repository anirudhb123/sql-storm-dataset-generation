
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        RTRIM(SUBSTRING(ca_street_name, PATINDEX('% %', ca_street_name) + 1, LEN(ca_street_name))) AS street_name,
        LEFT(ca_street_name, CHARINDEX(' ', ca_street_name) - 1) AS street_prefix,
        ca_city,
        ca_state,
        ca_country,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
CombinedStats AS (
    SELECT 
        A.full_address,
        G.cd_gender,
        G.gender_count,
        COUNT(H.hd_demo_sk) AS household_count
    FROM 
        AddressParts A
    JOIN 
        customer C ON A.ca_address_sk = C.c_current_addr_sk
    JOIN 
        GenderStats G ON C.c_current_cdemo_sk = G.cd_demo_sk
    LEFT JOIN 
        household_demographics H ON C.c_current_hdemo_sk = H.hd_demo_sk
    GROUP BY 
        A.full_address, G.cd_gender, G.gender_count
)
SELECT 
    full_address,
    cd_gender,
    gender_count,
    household_count,
    CONCAT('Address: ', full_address, ' | Gender: ', cd_gender, ' | Count: ', gender_count, ' | Households: ', household_count) AS details
FROM 
    CombinedStats
WHERE 
    household_count > 0
ORDER BY 
    full_address;
