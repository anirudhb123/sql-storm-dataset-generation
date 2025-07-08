
WITH AddressCounts AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses,
        LISTAGG(ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        COUNT(*) AS demo_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        CAST(d.d_date AS DATE) AS sale_date,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        sale_date
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.total_addresses,
    a.street_names,
    d.cd_gender,
    d.cd_marital_status,
    d.total_purchase_estimate,
    d.demo_count,
    s.sale_date,
    s.total_sales
FROM 
    AddressCounts a
JOIN 
    DemographicSummary d ON a.total_addresses > 10
JOIN 
    SalesSummary s ON s.sale_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
ORDER BY 
    a.ca_city, a.ca_state, d.cd_gender;
