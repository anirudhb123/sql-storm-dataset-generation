
WITH AddressSummary AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_street_name || ' ' || ca_street_type || ' ' || ca_street_number, ', ') AS full_address_list
    FROM customer_address
    GROUP BY ca_state, ca_city
),
CustomerInfo AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status,
        cd_education_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
RankedCustomers AS (
    SELECT 
        ci.cd_demo_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.total_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ci.total_purchase_estimate DESC) AS purchase_rank
    FROM CustomerInfo ci
)
SELECT 
    asum.ca_state,
    asum.ca_city,
    asum.total_addresses,
    STRING_AGG(rk.cd_gender || ': ' || rk.total_purchase_estimate || ' (Rank: ' || rk.purchase_rank || ')', '; ') AS customer_summary,
    asum.full_address_list
FROM AddressSummary asum
JOIN customer c ON asum.ca_address_sk = c.c_current_addr_sk
JOIN RankedCustomers rk ON c.c_current_cdemo_sk = rk.cd_demo_sk
GROUP BY asum.ca_state, asum.ca_city, asum.total_addresses, asum.full_address_list
ORDER BY asum.ca_state, asum.ca_city;
