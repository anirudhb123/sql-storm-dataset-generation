
WITH AddressSummary AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_street_name) AS unique_streets,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city
),
CustomerGenderSummary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        DATE(d.d_date) AS sales_date,
        SUM(ws.ws_quantity) AS total_items_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        AVG(ws.ws_list_price) AS avg_list_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        DATE(d.d_date)
)
SELECT 
    a.ca_state,
    a.ca_city,
    a.unique_addresses,
    a.unique_streets,
    a.street_types,
    a.total_street_name_length,
    g.cd_gender,
    g.total_customers,
    g.total_dependents,
    g.avg_purchase_estimate,
    s.sales_date,
    s.total_items_sold,
    s.total_sales_amount,
    s.avg_list_price
FROM 
    AddressSummary a
JOIN 
    CustomerGenderSummary g ON g.total_customers > 0
JOIN 
    SalesSummary s ON s.sales_date = CURRENT_DATE
WHERE 
    a.unique_addresses > 10
ORDER BY 
    a.ca_state, a.ca_city, g.cd_gender;
