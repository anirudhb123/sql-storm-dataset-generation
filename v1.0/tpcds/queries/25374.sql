
WITH demographic_analysis AS (
    SELECT 
        cd_gender, 
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), '; ') AS customer_names
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
address_analysis AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(ca_city || ' - ' || ca_street_name, '; ') AS city_streets
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
sales_analysis AS (
    SELECT 
        ws.ws_ship_date_sk, 
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_ship_date_sk
)
SELECT 
    da.cd_gender, 
    da.cd_marital_status, 
    da.customer_count, 
    da.avg_purchase_estimate, 
    da.total_dependents,
    aa.ca_state,
    aa.unique_addresses,
    aa.city_streets,
    sa.total_sales,
    sa.total_quantity
FROM 
    demographic_analysis da
JOIN 
    address_analysis aa ON 1=1
JOIN 
    sales_analysis sa ON 1=1
ORDER BY 
    da.cd_gender, da.cd_marital_status, aa.ca_state;
