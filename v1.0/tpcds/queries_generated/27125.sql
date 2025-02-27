
WITH address_summary AS (
    SELECT 
        CONCAT(ca_city, ', ', ca_state) AS location,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
customer_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_customer_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        ws_ship_date_sk, 
        SUM(ws_sales_price) AS total_sales,
        STRING_AGG(DISTINCT ws_web_site_sk::TEXT) AS web_sites
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    a.location,
    a.address_count,
    a.street_names,
    c.cd_gender,
    c.customer_count,
    c.total_dependents,
    c.avg_purchase_estimate,
    s.ws_ship_date_sk,
    s.total_sales,
    s.web_sites
FROM 
    address_summary a
JOIN 
    customer_summary c ON a.location IS NOT NULL 
JOIN 
    sales_summary s ON s.total_sales > 0
ORDER BY 
    a.address_count DESC, c.customer_count DESC, s.total_sales DESC;
