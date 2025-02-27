
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
    HAVING SUM(ss.ss_sales_price) IS NOT NULL
    UNION ALL
    SELECT
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_sales_price) + sh.total_sales AS total_sales,
        sh.sales_count
    FROM store s
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
)
SELECT
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.cd_credit_rating) AS max_credit_rating,
    SUM(ws.ws_sales_price) AS total_web_sales,
    SUM(cs.cs_sales_price) AS total_catalog_sales,
    SUM(ss.ss_sales_price) AS total_store_sales,
    RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS web_sales_rank,
    RANK() OVER (ORDER BY SUM(cs.cs_sales_price) DESC) AS catalog_sales_rank,
    RANK() OVER (ORDER BY SUM(ss.ss_sales_price) DESC) AS store_sales_rank
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY ca.ca_city
LIMIT 10;
