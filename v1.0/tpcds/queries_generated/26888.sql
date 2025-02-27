
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip), '; ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
JoinedSummary AS (
    SELECT 
        asum.ca_state,
        asum.unique_addresses,
        asum.full_address_list,
        ds.cd_gender,
        ds.avg_purchase_estimate,
        ds.marital_statuses
    FROM 
        AddressSummary asum
    JOIN 
        DemographicSummary ds ON asum.ca_state = LEFT(ds.cd_gender, 2)  -- Assuming state-code can be interpreted from gender for illustration
)
SELECT 
    js.ca_state,
    js.unique_addresses,
    js.full_address_list,
    js.cd_gender,
    js.avg_purchase_estimate,
    js.marital_statuses,
    LENGTH(js.full_address_list) AS total_length_of_addresses,
    REPLACE(js.full_address_list, ',', '|') AS formatted_address_list_info
FROM 
    JoinedSummary js
ORDER BY 
    js.unique_addresses DESC, 
    js.cd_gender;
