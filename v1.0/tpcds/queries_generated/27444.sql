
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS address_count,
        COUNT(DISTINCT ca_city) AS unique_cities,
        COUNT(DISTINCT ca_zip) AS unique_zips
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependencies
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesByItem AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_units_sold
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CategorySales AS (
    SELECT 
        i_category,
        SUM(ws_sales_price) AS total_category_sales,
        SUM(ws_quantity) AS total_category_units_sold
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_category
)
SELECT 
    ac.ca_state,
    ac.address_count,
    ac.unique_cities,
    ac.unique_zips,
    ds.cd_gender,
    ds.avg_purchase_estimate,
    ds.total_dependencies,
    si.total_sales,
    si.total_units_sold,
    cs.total_category_sales,
    cs.total_category_units_sold
FROM 
    AddressCounts ac
JOIN 
    DemographicStats ds ON ds.cd_gender IN ('M', 'F')
LEFT JOIN 
    SalesByItem si ON ac.address_count > 100
LEFT JOIN 
    CategorySales cs ON cs.total_category_units_sold > 500
ORDER BY 
    ac.ca_state, ds.cd_gender, cs.total_category_sales DESC;
