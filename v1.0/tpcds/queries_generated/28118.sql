
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_zip) AS unique_zip_count,
        COUNT(*) AS total_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
customer_summary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
date_summary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_id) AS total_days,
        MAX(d_dom) AS max_day_of_month,
        MIN(d_dom) AS min_day_of_month
    FROM 
        date_dim
    GROUP BY 
        d_year
),
item_summary AS (
    SELECT 
        i_category,
        COUNT(i_item_sk) AS total_items,
        AVG(i_current_price) AS avg_price,
        SUM(i_wholesale_cost) AS total_wholesale_cost
    FROM 
        item
    GROUP BY 
        i_category
)
SELECT 
    as.ca_state, 
    as.unique_zip_count, 
    as.total_addresses,
    cs.cd_gender, 
    cs.total_customers, 
    cs.avg_dependents, 
    cs.total_purchase_estimate,
    ds.d_year, 
    ds.total_days, 
    ds.max_day_of_month, 
    ds.min_day_of_month,
    is.i_category,
    is.total_items,
    is.avg_price,
    is.total_wholesale_cost
FROM 
    address_summary AS as 
JOIN 
    customer_summary AS cs ON as.unique_zip_count > 0
JOIN 
    date_summary AS ds ON extract(year from current_date) = ds.d_year
JOIN 
    item_summary AS is ON is.total_items > 0
ORDER BY 
    as.ca_state, 
    cs.cd_gender, 
    ds.d_year, 
    is.i_category;
