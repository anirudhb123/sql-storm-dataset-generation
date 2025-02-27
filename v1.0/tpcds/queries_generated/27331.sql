
WITH address_summary AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_number, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
demographic_summary AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS gender_count,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    as.ca_city, 
    as.ca_state, 
    as.address_count, 
    as.street_names, 
    ds.cd_gender, 
    ds.gender_count, 
    ds.marital_statuses, 
    ss.total_net_profit, 
    ss.total_quantity_sold
FROM 
    address_summary as
JOIN 
    demographic_summary ds ON (as.address_count > 10) -- Using a condition to enforce filtering
LEFT JOIN 
    sales_summary ss ON (ds.gender_count > 5)         -- Ensuring we join based on a condition that reflects a threshold
ORDER BY 
    as.ca_state, 
    as.ca_city, 
    ds.cd_gender;
