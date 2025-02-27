
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS unique_street_types
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_status_distribution
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Promotions AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        SUM(CASE WHEN cs.cs_order_number IS NOT NULL THEN 1 ELSE 0 END) AS sales_count
    FROM 
        promotion p
    LEFT JOIN 
        (SELECT cs_item_sk, cs_order_number 
         FROM catalog_sales 
         GROUP BY cs_item_sk, cs_order_number) cs ON p.p_item_sk = cs.cs_item_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
)
SELECT 
    a.ca_state,
    a.address_count,
    a.unique_cities,
    a.unique_street_types,
    d.cd_gender,
    d.demographic_count,
    d.avg_purchase_estimate,
    d.marital_status_distribution,
    p.p_promo_id,
    p.p_promo_name,
    p.sales_count
FROM 
    AddressSummary a
JOIN 
    DemographicSummary d ON TRUE
JOIN 
    Promotions p ON TRUE
ORDER BY 
    a.address_count DESC, d.demographic_count DESC, p.sales_count DESC
LIMIT 10;
