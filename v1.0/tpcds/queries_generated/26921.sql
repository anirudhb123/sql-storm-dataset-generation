
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicCounts AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    ac.ca_city,
    ac.address_count,
    ac.full_address_list,
    dc.cd_gender,
    dc.demographic_count,
    ss.total_sales,
    ss.total_orders
FROM 
    AddressCounts ac
LEFT JOIN 
    DemographicCounts dc ON ac.address_count > 10  -- Arbitrary condition to join 
LEFT JOIN 
    SalesSummary ss ON ss.total_sales > 5000  -- Arbitrary condition to join
ORDER BY 
    ac.address_count DESC, dc.demographic_count DESC, ss.total_sales DESC;
