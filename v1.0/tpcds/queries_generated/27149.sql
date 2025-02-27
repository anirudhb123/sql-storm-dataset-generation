
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS addr_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
FilteredDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
    WHERE 
        cd_gender IN ('M', 'F') AND
        cd_purchase_estimate > 1000
),
DetailedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.ca_country,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    ds.web_site_id,
    ds.total_sales,
    ds.total_orders,
    ds.avg_profit,
    CONCAT(a.ca_city, ', ', a.ca_state, ', ', a.ca_country) AS full_address,
    LENGTH(a.ca_city) + LENGTH(a.ca_state) + LENGTH(a.ca_country) AS address_length
FROM 
    RankedAddresses a
JOIN 
    FilteredDemographics d ON a.addr_rank <= d.cd_demo_sk
JOIN 
    DetailedSales ds ON LENGTH(a.ca_city) = LENGTH(ds.web_site_id) % 26
WHERE 
    a.addr_rank <= 10
ORDER BY 
    ds.total_sales DESC, address_length ASC
LIMIT 100;
