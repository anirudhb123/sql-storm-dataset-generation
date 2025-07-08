
WITH AddressSummary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        LISTAGG(ca_street_name, '; ') WITHIN GROUP (ORDER BY ca_street_name) AS all_streets,
        LISTAGG(DISTINCT ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_type) AS unique_street_types
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demo_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        CAST(d.d_date AS DATE) AS sale_date,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        CAST(d.d_date AS DATE)
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.all_streets,
    a.unique_street_types,
    d.cd_gender,
    d.cd_marital_status,
    d.demo_count,
    d.total_dependents,
    s.sale_date,
    s.total_sales,
    s.total_quantity,
    s.order_count
FROM 
    AddressSummary a
JOIN 
    DemographicSummary d ON a.address_count > 100 AND d.demo_count > 50
JOIN 
    SalesSummary s ON s.sale_date BETWEEN '2023-01-01' AND '2023-12-31'
WHERE 
    a.ca_state = 'CA'
ORDER BY 
    a.address_count DESC, 
    d.demo_count DESC, 
    s.total_sales DESC
LIMIT 100;
