
WITH address_summary AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS unique_addresses, 
        LISTAGG(DISTINCT ca_city, ', ') WITHIN GROUP (ORDER BY ca_city) AS cities,
        LISTAGG(DISTINCT CONCAT(ca_street_name, ' ', ca_street_type), ', ') WITHIN GROUP (ORDER BY ca_street_name, ca_street_type) AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
), demographic_summary AS (
    SELECT 
        cd_gender, 
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(DISTINCT cd_marital_status, ', ') WITHIN GROUP (ORDER BY cd_marital_status) AS marital_statuses
    FROM 
        customer_demographics 
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
), sales_summary AS (
    SELECT 
        d_year, 
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS distinct_sales_orders
    FROM 
        web_sales
    JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state, 
    a.unique_addresses, 
    a.cities, 
    a.street_names,
    d.cd_gender, 
    d.customer_count, 
    d.avg_purchase_estimate,
    d.marital_statuses,
    s.d_year, 
    s.total_net_profit, 
    s.distinct_sales_orders
FROM 
    address_summary a
JOIN 
    demographic_summary d ON TRUE
JOIN 
    sales_summary s ON TRUE
ORDER BY 
    a.ca_state, 
    d.cd_gender, 
    s.d_year;
