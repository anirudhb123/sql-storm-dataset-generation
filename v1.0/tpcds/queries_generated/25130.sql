
WITH Address_Statistics AS (
    SELECT 
        ca_city,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        AVG(LENGTH(ca_suite_number)) AS avg_suite_length,
        SUM(CASE WHEN ca_state = 'CA' THEN 1 ELSE 0 END) AS ca_address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographics_Statistics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dep_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Sales_Statistics AS (
    SELECT 
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS sales_rank,
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.ca_city,
    a.total_addresses,
    a.avg_street_name_length,
    a.avg_suite_length,
    a.ca_address_count,
    d.cd_gender,
    d.total_customers,
    d.avg_dep_count,
    d.avg_purchase_estimate,
    d.highest_credit_rating,
    s.sales_rank,
    s.total_profit
FROM 
    Address_Statistics a
JOIN 
    Demographics_Statistics d ON d.total_customers >= 50
JOIN 
    Sales_Statistics s ON s.total_profit > 5000
ORDER BY 
    a.ca_city, d.cd_gender, s.sales_rank;
