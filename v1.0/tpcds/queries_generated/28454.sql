
WITH AddressWordCounts AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        LENGTH(ca_street_name) - LENGTH(REPLACE(ca_street_name, ' ', '')) + 1 AS street_word_count,
        LENGTH(ca_street_type) - LENGTH(REPLACE(ca_street_type, ' ', '')) + 1 AS street_type_word_count,
        LENGTH(ca_street_number) - LENGTH(REPLACE(ca_street_number, ' ', '')) + 1 AS street_number_word_count
    FROM 
        customer_address
),
CustomerDemoGender AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(c_demo_sk) AS customer_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender
),
AggregateData AS (
    SELECT
        a.ca_state,
        SUM(a.street_word_count) AS total_street_words,
        SUM(a.street_type_word_count) AS total_street_type_words,
        SUM(a.street_number_word_count) AS total_street_number_words,
        SUM(cd.customer_count) AS total_customers,
        AVG(cd.customer_count) AS avg_customers_per_gender
    FROM 
        AddressWordCounts AS a
    LEFT JOIN 
        CustomerDemoGender AS cd ON a.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk)
    GROUP BY 
        a.ca_state
)
SELECT 
    ca_state,
    total_street_words,
    total_street_type_words,
    total_street_number_words,
    total_customers,
    avg_customers_per_gender,
    CASE 
        WHEN total_customers > 100 THEN 'High Activity'
        WHEN total_customers BETWEEN 50 AND 100 THEN 'Medium Activity'
        ELSE 'Low Activity' 
    END AS activity_level
FROM 
    AggregateData
ORDER BY 
    total_customers DESC;
