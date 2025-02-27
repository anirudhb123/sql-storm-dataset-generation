
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
SalesSummary AS (
    SELECT 
        ca.ca_country,
        SUM(cs.total_web_sales) AS total_web_sales_by_country,
        SUM(cs.total_catalog_sales) AS total_catalog_sales_by_country,
        SUM(cs.total_store_sales) AS total_store_sales_by_country
    FROM CustomerSales cs
    JOIN customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
    GROUP BY ca.ca_country
),
SalesRanked AS (
    SELECT 
        country,
        total_web_sales_by_country,
        total_catalog_sales_by_country,
        total_store_sales_by_country,
        RANK() OVER (ORDER BY total_web_sales_by_country DESC) AS web_sales_rank,
        RANK() OVER (ORDER BY total_catalog_sales_by_country DESC) AS catalog_sales_rank,
        RANK() OVER (ORDER BY total_store_sales_by_country DESC) AS store_sales_rank
    FROM SalesSummary
)
SELECT 
    country,
    total_web_sales_by_country,
    web_sales_rank,
    total_catalog_sales_by_country,
    catalog_sales_rank,
    total_store_sales_by_country,
    store_sales_rank
FROM SalesRanked
WHERE web_sales_rank <= 10 OR catalog_sales_rank <= 10 OR store_sales_rank <= 10
ORDER BY web_sales_rank, catalog_sales_rank, store_sales_rank;
