
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_tickets
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
demographics AS (
    SELECT 
        ca.ca_country, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        SUM(cs.total_store_sales) AS total_store_sales,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count
    FROM 
        customer_sales cs
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_country, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    d.ca_country, 
    d.cd_gender,
    COUNT(d.customer_count) AS num_customers, 
    AVG(d.total_web_sales) AS avg_web_sales,
    AVG(d.total_catalog_sales) AS avg_catalog_sales,
    AVG(d.total_store_sales) AS avg_store_sales
FROM 
    demographics d
GROUP BY 
    d.ca_country, d.cd_gender
ORDER BY 
    num_customers DESC, avg_web_sales DESC
LIMIT 10;
