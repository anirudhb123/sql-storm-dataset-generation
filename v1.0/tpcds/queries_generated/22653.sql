
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank,
        COUNT(*) OVER () as total_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
AddressStats AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        COUNT(DISTINCT CASE WHEN cd.cd_marital_status = 'M' THEN c.c_customer_id END) AS married_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        CASE 
            WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High'
            WHEN SUM(ws.ws_net_paid) BETWEEN 100 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS sales_category
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    as.address_sk,
    as.customer_count,
    as.married_count,
    ss.total_sales,
    ss.sales_category,
    (SELECT AVG(cd.cd_purchase_estimate)
     FROM customer_demographics cd
     WHERE cd.cd_marital_status = 'M' AND cd.cd_purchase_estimate IS NOT NULL
    ) AS avg_married_purchase_estimate,
    (SELECT COUNT(DISTINCT ca.ca_address_sk)
     FROM customer_address ca
     WHERE ca.ca_city IS NOT NULL
    ) AS distinct_city_count
FROM 
    CustomerStats cs
JOIN 
    AddressStats as ON cs.c_customer_sk = as.customer_count
JOIN 
    SalesSummary ss ON ss.web_site_sk = cs.c_customer_sk % (SELECT COUNT(web_site_sk) FROM web_site)
WHERE 
    cs.rank <= 10 AND 
    cs.total_customers IS NOT NULL
ORDER BY 
    ss.total_sales DESC, 
    cs.c_last_name ASC;
