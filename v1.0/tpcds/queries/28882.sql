
WITH AddressCounts AS (
    SELECT
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS street_info
    FROM customer_address
    GROUP BY ca_city
),
CustomerSummary AS (
    SELECT
        cd_gender,
        COUNT(*) AS customer_count,
        STRING_AGG(c_first_name || ' ' || c_last_name, ', ') AS customer_names
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
CombinedSummary AS (
    SELECT
        ac.ca_city,
        ac.address_count,
        ac.street_info,
        cs.cd_gender,
        cs.customer_count,
        cs.customer_names
    FROM AddressCounts ac
    LEFT JOIN CustomerSummary cs ON cs.customer_count > 0
    ORDER BY ac.address_count DESC, cs.customer_count DESC
)
SELECT
    CONCAT('City: ', ca_city, ' | Address Count: ', address_count, ' | Streets: ', street_info, ' | Gender: ', cd_gender, ' | Customer Count: ', customer_count, ' | Customers: ', customer_names) AS Full_Summary
FROM CombinedSummary
WHERE address_count > 5
ORDER BY address_count DESC, customer_count DESC;
