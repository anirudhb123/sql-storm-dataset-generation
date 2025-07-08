
WITH AddressData AS (
    SELECT 
        ca_city, 
        ca_state, 
        ca_country, 
        COUNT(*) AS num_addresses,
        LISTAGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS unique_streets
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state, 
        ca_country
), 
DemographicsData AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status
), 
SalesSummary AS (
    SELECT 
        DATE_TRUNC('month', d_date) AS sales_month,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        sales_month
)
SELECT 
    A.ca_city,
    A.ca_state,
    A.ca_country,
    A.num_addresses,
    A.unique_streets,
    D.cd_gender,
    D.cd_marital_status,
    D.total_purchase_estimate,
    D.avg_dependents,
    S.sales_month,
    S.total_sales
FROM 
    AddressData A
JOIN 
    DemographicsData D ON A.ca_country = 'USA'
CROSS JOIN 
    SalesSummary S
ORDER BY 
    A.ca_city, 
    D.cd_gender, 
    S.sales_month DESC;
