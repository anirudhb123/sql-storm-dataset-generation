
WITH CustomerStatistics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        AVG(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
AddressStatistics AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_id) AS num_customers,
        AVG(c.cd_dep_count) AS avg_dependencies
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_country
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.avg_sales_price,
    cs.total_orders,
    cs.total_quantity,
    as.ca_country,
    as.num_customers,
    as.avg_dependencies
FROM 
    CustomerStatistics cs
JOIN 
    AddressStatistics as ON cs.c_customer_id IN (SELECT c.c_customer_id FROM customer c JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk)
WHERE 
    cs.total_orders > 10 
ORDER BY 
    cs.avg_sales_price DESC, cs.total_quantity DESC
LIMIT 100;
