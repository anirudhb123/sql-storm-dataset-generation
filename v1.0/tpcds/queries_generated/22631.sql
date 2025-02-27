
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) -- last 30 days
    GROUP BY 
        ws.web_site_sk, 
        ws_sold_date_sk
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        MAX(cd.cd_income_band_sk) AS max_income_band,
        COUNT(DISTINCT cd.cd_demo_sk) AS demographics_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_country,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
    SUM(cs.cs_sales_price) AS total_revenue,
    AVG(cs.cs_sales_price) AS avg_catalog_sale,
    COUNT(DISTINCT cds.c_customer_sk) AS unique_customers,
    MAX(cd.cd_credit_rating) AS highest_credit_rating
FROM 
    catalog_sales cs
FULL OUTER JOIN 
    CustomerStatistics cds ON cs.cs_bill_customer_sk = cds.c_customer_sk
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = cds.c_customer_sk)
WHERE 
    ca.ca_country IS NOT NULL AND 
    (ca.ca_state IS NULL OR ca.ca_state = 'CA' OR ca.ca_state = 'NY') -- States of interest
GROUP BY 
    ca.ca_country
HAVING 
    total_catalog_sales > 10
ORDER BY 
    total_revenue DESC
LIMIT 10;
