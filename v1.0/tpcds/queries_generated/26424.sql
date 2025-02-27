
WITH address_summary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
), 
demographic_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
), 
sales_summary AS (
    SELECT 
        s_store_name,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_items_sold
    FROM 
        store_sales
    INNER JOIN 
        store ON store.s_store_sk = store_sales.ss_store_sk
    GROUP BY 
        s_store_name
),
date_analysis AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(*) AS sales_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    INNER JOIN 
        date_dim ON date_dim.d_date_sk = web_sales.ws_sold_date_sk
    GROUP BY 
        d_year, d_month_seq
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.unique_addresses,
    a.full_address_list,
    d.cd_gender,
    d.cd_marital_status,
    d.avg_purchase_estimate,
    d.demographic_count,
    s.s_store_name,
    s.total_sales,
    s.total_items_sold,
    da.sales_count,
    da.total_profit
FROM 
    address_summary a 
JOIN 
    demographic_summary d ON a.ca_state = d.cd_gender  -- Sample join condition
JOIN 
    sales_summary s ON a.ca_city = s.s_store_name     -- Sample join condition
JOIN 
    date_analysis da ON da.d_year = 2023               -- Sample filtering condition for the year
WHERE 
    d.demographic_count > 100
ORDER BY 
    total_sales DESC, 
    avg_purchase_estimate DESC
LIMIT 100;
