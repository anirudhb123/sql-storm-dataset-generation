
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
AddressStats AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY ca.ca_city
),
SalesRank AS (
    SELECT 
        city,
        customer_count,
        total_catalog_sales,
        total_web_sales,
        total_store_sales,
        RANK() OVER (ORDER BY total_catalog_sales + total_web_sales + total_store_sales DESC) AS sales_rank
    FROM (
        SELECT 
            ca.ca_city,
            COUNT(DISTINCT c.c_customer_id) AS customer_count,
            SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS total_catalog_sales,
            SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales,
            SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_store_sales
        FROM customer_address ca
        JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
        GROUP BY ca.ca_city
    ) AS aggregated_sales
)

SELECT 
    city,
    customer_count,
    total_catalog_sales,
    total_web_sales,
    total_store_sales,
    sales_rank
FROM SalesRank
WHERE sales_rank <= 10
ORDER BY sales_rank;
