
WITH address_stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographic_stats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
customer_stats AS (
    SELECT 
        c.c_country,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(CASE WHEN c.c_birth_month = 6 THEN 1 ELSE 0 END) AS birthday_in_june_count
    FROM 
        customer c
    GROUP BY 
        c.c_country
),
sales_summary AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_net_profit) AS total_sales_profit,
        COUNT(*) AS total_sales,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    d.cd_gender,
    d.avg_purchase_estimate,
    c.total_customers,
    c.birthday_in_june_count,
    s.total_sales_profit,
    s.total_sales,
    s.total_quantity_sold
FROM 
    address_stats a
JOIN 
    demographic_stats d ON a.address_count > 100
JOIN 
    customer_stats c ON c.total_customers > 50
JOIN 
    sales_summary s ON s.total_sales > 200
ORDER BY 
    a.address_count DESC, d.avg_purchase_estimate DESC;
