
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        MAX(LEN(ca_street_name)) AS max_street_name_length,
        AVG(LEN(ca_street_name)) AS avg_street_name_length,
        STRING_AGG(ca_street_name, ', ') AS all_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemoStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS total_demographics,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses,
        STRING_AGG(cd_education_status, ', ') AS education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
ItemStats AS (
    SELECT
        i_category,
        COUNT(*) AS total_items,
        STRING_AGG(DISTINCT i_color, ', ') AS unique_colors,
        MAX(i_current_price) AS max_price,
        MIN(i_current_price) AS min_price
    FROM 
        item
    GROUP BY 
        i_category
)
SELECT 
    A.ca_state,
    A.total_addresses,
    A.max_street_name_length,
    A.avg_street_name_length,
    D.cd_gender,
    D.total_demographics,
    D.marital_statuses,
    D.education_statuses,
    I.i_category,
    I.total_items,
    I.unique_colors,
    I.max_price,
    I.min_price
FROM 
    AddressStats A
JOIN 
    DemoStats D ON A.ca_state IN ('CA', 'NY', 'TX')  -- Filtering on popular states
JOIN 
    ItemStats I ON I.total_items > 50  -- Filtering for item categories with a significant number of products
ORDER BY 
    A.total_addresses DESC, 
    D.total_demographics DESC,
    I.total_items DESC;
