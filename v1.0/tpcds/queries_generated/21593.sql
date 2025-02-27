
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(css.cs_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT css.cs_order_number) AS catalog_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales css ON c.c_customer_sk = css.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesRanks AS (
    SELECT 
        c.customer_sk,
        total_web_sales,
        total_catalog_sales,
        web_order_count,
        catalog_order_count,
        DENSE_RANK() OVER (PARTITION BY (CASE WHEN total_web_sales > total_catalog_sales THEN 'web' ELSE 'catalog' END) 
            ORDER BY total_web_sales + total_catalog_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    c.c_customer_id,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
    CASE 
        WHEN cs.total_web_sales IS NOT NULL THEN 'Web'
        WHEN cs.total_catalog_sales IS NOT NULL THEN 'Catalog'
        ELSE 'No Sales'
    END AS Sales_Type,
    wr.wr_return_amt,
    CASE 
        WHEN cs.total_web_sales > 0 AND cs.total_catalog_sales > 0 THEN 'Both Channels'
        WHEN cs.total_web_sales > 0 THEN 'Web Only'
        WHEN cs.total_catalog_sales > 0 THEN 'Catalog Only'
        ELSE 'No Activity'
    END AS Sales_Activity,
    CASE 
        WHEN sr.sales_rank = 1 THEN 'Top Performer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    CustomerSales cs
INNER JOIN 
    sales_ranks sr ON cs.c_customer_sk = sr.customer_sk
LEFT JOIN 
    web_returns wr ON cs.c_customer_sk = wr.wr_returning_customer_sk
JOIN 
    customer c ON c.c_customer_sk = sr.customer_sk
WHERE 
    cs.web_order_count > 2 
    OR (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) > 5
ORDER BY 
    total_web_sales DESC, total_catalog_sales ASC
FETCH FIRST 50 ROWS ONLY;
