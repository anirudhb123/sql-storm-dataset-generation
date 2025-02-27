
WITH AddressAggregates AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsAggregates AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesAggregates AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        STRING_AGG(DISTINCT sm.sm_type, ', ') AS shipping_methods
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.web_site_id
)
SELECT 
    aa.ca_state,
    aa.address_count,
    aa.cities,
    aa.street_types,
    da.cd_gender,
    da.total_dependents,
    da.avg_purchase_estimate,
    da.education_statuses,
    sa.web_site_id,
    sa.total_profit,
    sa.total_orders,
    sa.shipping_methods
FROM 
    AddressAggregates aa
JOIN 
    DemographicsAggregates da ON TRUE
JOIN 
    SalesAggregates sa ON TRUE
ORDER BY 
    aa.ca_state, da.cd_gender, sa.total_profit DESC;
