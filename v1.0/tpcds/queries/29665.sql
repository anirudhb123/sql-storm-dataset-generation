
WITH DemographicCounts AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS total_customers,
        MAX(cd_dep_count) AS max_dependents,
        MIN(cd_dep_count) AS min_dependents,
        AVG(cd_dep_count) AS avg_dependents,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS unique_education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
SalesStatistics AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid) AS avg_order_value,
        STRING_AGG(DISTINCT wp_type, ', ') AS unique_web_page_types
    FROM 
        web_sales
    JOIN 
        web_page ON ws_web_page_sk = wp_web_page_sk
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    dc.cd_gender,
    dc.cd_marital_status,
    dc.total_customers,
    dc.max_dependents,
    dc.min_dependents,
    dc.avg_dependents,
    dc.unique_education_statuses,
    ac.address_count,
    ac.cities,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_order_value,
    ss.unique_web_page_types
FROM 
    DemographicCounts dc
JOIN 
    AddressCounts ac ON ac.cities LIKE CONCAT('%', dc.cd_gender, '%')
JOIN 
    SalesStatistics ss ON ss.ws_bill_cdemo_sk IN (
        SELECT c_customer_sk 
        FROM customer 
        WHERE c_customer_id = dc.cd_gender
    )
ORDER BY 
    dc.cd_gender, dc.cd_marital_status;
