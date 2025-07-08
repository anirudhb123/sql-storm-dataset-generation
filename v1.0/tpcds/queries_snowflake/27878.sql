
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        LISTAGG(DISTINCT ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS all_street_names
    FROM 
        customer_address
    WHERE 
        ca_state IS NOT NULL
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(c.c_customer_sk) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        LISTAGG(DISTINCT cd_education_status, ', ') WITHIN GROUP (ORDER BY cd_education_status) AS education_levels
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        LISTAGG(DISTINCT i.i_item_desc, ', ') WITHIN GROUP (ORDER BY i.i_item_desc) AS sold_items
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        d.d_year
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.all_street_names,
    c.cd_gender,
    c.total_customers,
    c.total_dependents,
    c.education_levels,
    s.d_year,
    s.total_sales,
    s.sold_items
FROM 
    AddressSummary AS a
JOIN 
    CustomerDemographics AS c ON a.ca_state IS NOT NULL
JOIN 
    SalesSummary AS s ON s.d_year IS NOT NULL
ORDER BY 
    a.ca_state, c.cd_gender, s.d_year;
