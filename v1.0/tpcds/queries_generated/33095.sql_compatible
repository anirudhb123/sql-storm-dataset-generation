
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_citem_sk, 
        ws_web_site_sk, 
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_citem_sk, 
        ws_web_site_sk
    HAVING 
        SUM(ws_quantity) > 100
),
Address_CTE AS (
    SELECT 
        ca_address_sk,
        ca_city,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_address_sk, 
        ca_city
),
Demographics AS (
    SELECT 
        cd_gender, 
        COUNT(c_customer_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_city,
    d.cd_gender,
    d.demographic_count,
    d.avg_purchase_estimate,
    s.total_sales,
    COALESCE(s.sales_rank, 0) AS sales_rank
FROM 
    Address_CTE a
LEFT JOIN 
    Demographics d ON a.customer_count > 50 AND d.demographic_count > 10
LEFT JOIN 
    Sales_CTE s ON a.ca_address_sk = s.ws_web_site_sk
WHERE 
    a.ca_city IS NOT NULL 
    AND (d.cd_gender IS NULL OR d.cd_gender = 'M')
ORDER BY 
    a.ca_city, 
    d.demographic_count DESC;
