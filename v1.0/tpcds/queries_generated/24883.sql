
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0) AS total_sales,
        CASE 
            WHEN total_web_sales IS NULL AND total_catalog_sales IS NULL AND total_store_sales IS NULL THEN 'No Sales'
            WHEN total_web_sales IS NOT NULL AND total_web_sales > 0 THEN 'Internet Sales'
            WHEN total_store_sales IS NOT NULL AND total_store_sales > 0 THEN 'Physical Store Sales'
            ELSE 'Undefined Sales Type'
        END AS sales_type
    FROM 
        CustomerSales c
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY sales_type ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    r.c_customer_id,
    r.sales_type,
    r.total_sales,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_type, r.total_sales DESC;

-- Additional bizarre logic regarding shipping and refunded amounts
SELECT 
    ws.ws_order_number,
    ws.ws_sales_price,
    COALESCE(NULLIF(ws.ws_sales_price, 0), ws.ws_net_paid) * 
    CASE 
        WHEN ws.ws_sales_price < 50 THEN 1.05
        WHEN ws.ws_sales_price BETWEEN 50 AND 100 THEN 1.10
        ELSE 1.20
    END AS adjusted_sales_price 
FROM 
    web_sales ws
WHERE 
    EXISTS (
        SELECT 1 
        FROM store_returns sr 
        WHERE sr.sr_ticket_number = ws.ws_order_number 
        AND sr.sr_return_quantity > 0
    )
AND 
    ws.ws_sales_price IS NOT NULL
ORDER BY 
    adjusted_sales_price DESC
LIMIT 100;

-- Additionally, checks for NULL and unusual sales computations
SELECT 
    DISTINCT c.c_customer_id,
    CASE 
        WHEN SUM(ws.ws_sales_price) IS NULL THEN 'No Web Sales'
        WHEN SUM(ss.ss_sales_price) IS NULL THEN 'No Store Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
GROUP BY 
    c.c_customer_id
HAVING 
    COUNT(ws.ws_sales_price) = 0 OR COUNT(ss.ss_sales_price) = 0;
