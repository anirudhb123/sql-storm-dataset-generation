
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesPerformance AS (
    SELECT 
        CASE 
            WHEN ws_bill_cdemo_sk IS NOT NULL THEN 'Web Sales'
            WHEN cs_bill_cdemo_sk IS NOT NULL THEN 'Catalog Sales'
            WHEN ss_cdemo_sk IS NOT NULL THEN 'Store Sales'
            ELSE 'Unknown'
        END AS sale_type,
        COUNT(*) AS total_sales,
        SUM(COALESCE(ws_ext_sales_price, cs_ext_sales_price, ss_ext_sales_price, 0)) AS total_revenue
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    GROUP BY 
        sale_type
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    sp.sale_type,
    sp.total_sales,
    sp.total_revenue,
    SUBSTRING(cd.cd_education_status, 1, 5) AS short_education_status,
    REPLACE(cd.cd_gender, 'M', 'Male') AS gender_full
FROM 
    CustomerDetails cd
JOIN 
    SalesPerformance sp ON cd.c_customer_sk = sp.c_customer_sk
WHERE 
    cd.ca_state IN ('CA', 'NY')
ORDER BY 
    sp.total_revenue DESC
LIMIT 100;
