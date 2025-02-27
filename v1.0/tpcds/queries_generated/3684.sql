
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_sales_price, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_sales_price, 0)) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
SalesRanked AS (
    SELECT 
        c.customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        RANK() OVER (ORDER BY total_web_sales + total_catalog_sales + total_store_sales DESC) AS sales_rank
    FROM CustomerSales c
),
FilteredSales AS (
    SELECT 
        customer_id, 
        total_web_sales, 
        total_catalog_sales, 
        total_store_sales, 
        sales_rank
    FROM SalesRanked
    WHERE sales_rank <= 10
)
SELECT 
    fs.customer_id,
    fs.total_web_sales,
    fs.total_catalog_sales,
    fs.total_store_sales,
    COALESCE(fs.total_web_sales, 0) + COALESCE(fs.total_catalog_sales, 0) + COALESCE(fs.total_store_sales, 0) AS total_combined_sales,
    CASE 
        WHEN fs.total_web_sales IS NULL THEN 'No Web Sales'
        ELSE 'Web Sales Present'
    END AS web_sales_status
FROM FilteredSales fs
LEFT JOIN customer_address ca ON ca.ca_address_sk = (
    SELECT c.c_current_addr_sk
    FROM customer c 
    WHERE c.c_customer_id = fs.customer_id
)
WHERE ca.ca_state = 'CA';
