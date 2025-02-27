
WITH Address_Stats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        AVG(LENGTH(ca_city)) AS avg_city_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Customer_Stats AS (
    SELECT
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(c_customer_sk) AS total_customers,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Sales_Stats AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_items_sold
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    ds.d_date AS sales_date,
    as.ca_state,
    as.unique_addresses,
    as.avg_street_name_length,
    as.avg_city_name_length,
    cs.cd_gender,
    cs.avg_purchase_estimate,
    cs.total_customers,
    cs.marital_statuses,
    ss.total_sales,
    ss.total_orders,
    ss.total_items_sold
FROM 
    date_dim ds
LEFT JOIN 
    Address_Stats as ON ds.d_date_sk = as.ca_state 
LEFT JOIN 
    Customer_Stats cs ON ds.d_date_sk = cs.cd_gender
LEFT JOIN 
    Sales_Stats ss ON ds.d_date_sk = ss.ws_ship_date_sk
WHERE 
    ds.d_year = 2023
ORDER BY 
    sales_date, as.ca_state, cs.cd_gender;
