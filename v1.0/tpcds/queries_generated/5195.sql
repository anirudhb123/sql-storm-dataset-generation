
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c 
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    GROUP BY c.c_customer_id
),
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(CASE WHEN cs.total_catalog_sales >= 1000 THEN 1 ELSE 0 END) AS high_value_customers,
        SUM(CASE WHEN cs.total_web_sales >= 1000 THEN 1 ELSE 0 END) AS high_value_web_customers
    FROM customer_demographics cd
    JOIN customer_sales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE cd.cd_gender = 'F'
    GROUP BY cd.cd_demo_sk
),
sales_distribution AS (
    SELECT 
        CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog'
            WHEN total_store_sales > total_web_sales AND total_store_sales > total_catalog_sales THEN 'Store'
            ELSE 'Equal'
        END AS preferred_channel,
        COUNT(*) AS customer_count
    FROM customer_sales
    GROUP BY preferred_channel
)
SELECT 
    demo.cd_demo_sk,
    demo.high_value_customers,
    demo.high_value_web_customers,
    sd.preferred_channel,
    sd.customer_count
FROM customer_demo demo
JOIN sales_distribution sd ON demo.cd_demo_sk = sd.customer_count
ORDER BY demo.cd_demo_sk;
