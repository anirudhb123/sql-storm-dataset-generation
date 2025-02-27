
WITH AddressAggregates AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT
        i_item_id,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_amount,
        STRING_AGG(DISTINCT ws_ship_mode_sk::TEXT, ', ') AS shipping_modes
    FROM 
        web_sales
    JOIN 
        item ON ws_item_sk = i_item_sk
    GROUP BY 
        i_item_id
)

SELECT 
    aa.ca_state,
    aa.address_count,
    aa.cities,
    aa.street_names,
    cd.cd_gender,
    cd.demographic_count,
    cd.education_statuses,
    ss.i_item_id,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.shipping_modes
FROM 
    AddressAggregates aa
JOIN 
    CustomerDemographics cd ON aa.address_count > 100
JOIN 
    SalesSummary ss ON ss.total_quantity_sold > 1000
ORDER BY 
    aa.ca_state, cd.cd_gender, ss.total_sales_amount DESC;
