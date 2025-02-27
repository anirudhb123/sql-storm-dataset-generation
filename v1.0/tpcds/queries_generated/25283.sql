
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerSummary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
DateSummary AS (
    SELECT 
        d_year,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_count,
        COUNT(d_date) AS total_days
    FROM 
        date_dim
    GROUP BY 
        d_year
),
ItemSummary AS (
    SELECT 
        i_brand,
        COUNT(i_item_sk) AS item_count,
        SUM(i_current_price) AS total_value,
        STRING_AGG(DISTINCT i_color, ', ') AS colors
    FROM 
        item
    GROUP BY 
        i_brand
)
SELECT 
    a.ca_state,
    a.address_count,
    a.avg_gmt_offset,
    a.cities,
    a.street_types,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    d.d_year,
    d.holiday_count,
    d.total_days,
    i.i_brand,
    i.item_count,
    i.total_value,
    i.colors
FROM 
    AddressSummary a
JOIN 
    CustomerSummary c ON a.address_count > 50
JOIN 
    DateSummary d ON d.total_days > 350
JOIN 
    ItemSummary i ON i.total_value > 10000
ORDER BY 
    a.address_count DESC, c.customer_count DESC;
