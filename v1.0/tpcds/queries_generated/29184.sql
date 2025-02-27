
WITH CustomerAddressAggregates AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(ca_gmt_offset) AS average_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographicsData AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS total_demographics,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateDimensionStats AS (
    SELECT 
        d_year,
        COUNT(d_date_sk) AS days_in_year,
        SUM(d_same_day_ly) AS total_same_day_last_year
    FROM 
        date_dim
    GROUP BY 
        d_year
),
WarehouseInfo AS (
    SELECT 
        w_state,
        SUM(w_warehouse_sq_ft) AS total_sq_ft,
        MAX(w_warehouse_name) AS largest_warehouse
    FROM 
        warehouse
    GROUP BY 
        w_state
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.average_offset,
    d.cd_gender,
    d.total_demographics,
    d.total_dependents,
    y.d_year,
    y.days_in_year,
    y.total_same_day_last_year,
    w.total_sq_ft,
    w.largest_warehouse
FROM 
    CustomerAddressAggregates a
JOIN 
    CustomerDemographicsData d ON a.ca_state = (
        SELECT ca_state 
        FROM customer_address 
        WHERE ca_address_sk = (SELECT MIN(c_current_addr_sk) FROM customer WHERE c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = d.cd_gender))
    )
JOIN 
    DateDimensionStats y ON y.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
JOIN 
    WarehouseInfo w ON w.w_state = a.ca_state
WHERE 
    a.unique_addresses > 100
ORDER BY 
    a.unique_addresses DESC, d.total_demographics DESC;
