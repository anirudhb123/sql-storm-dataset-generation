
WITH AddressAnalysis AS (
    SELECT 
        ca_country,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities,
        STRING_AGG(DISTINCT ca_state, ', ') AS unique_states,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_country
),
DemographicAnalysis AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS count_by_gender,
        SUM(cd_dep_count) AS total_dependencies,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
SalesAnalysis AS (
    SELECT 
        i.i_brand AS item_brand,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales_count,
        SUM(ws.ws_ext_sales_price) AS total_sales_value,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_brand
)
SELECT 
    aa.ca_country,
    aa.customer_count,
    aa.unique_cities,
    aa.unique_states,
    aa.avg_gmt_offset,
    da.cd_gender,
    da.count_by_gender,
    da.total_dependencies,
    da.marital_statuses,
    sa.item_brand,
    sa.total_sales_count,
    sa.total_sales_value,
    sa.avg_sales_price
FROM 
    AddressAnalysis aa
JOIN 
    DemographicAnalysis da ON aa.customer_count > 100
JOIN 
    SalesAnalysis sa ON sa.total_sales_count > 50
ORDER BY 
    aa.ca_country, da.cd_gender, sa.total_sales_count DESC;
