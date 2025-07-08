
WITH address_analysis AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        LISTAGG(ca_street_name || ' ' || ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS street_names,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
customer_analysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(CONCAT(cd_gender, ' - ', cd_marital_status), '; ') WITHIN GROUP (ORDER BY cd_gender) AS demographic_info
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_sales,
        LISTAGG(DISTINCT CAST(ws_web_page_sk AS STRING), ', ') WITHIN GROUP (ORDER BY ws_web_page_sk) AS unique_web_pages
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT
    a.ca_city,
    a.address_count,
    a.street_names,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    s.total_quantity_sold,
    s.total_sales,
    s.unique_web_pages
FROM 
    address_analysis a
JOIN 
    customer_analysis c ON a.address_count > 100   
JOIN 
    sales_summary s ON a.address_count < 1000      
ORDER BY 
    a.address_count DESC, c.customer_count DESC;
