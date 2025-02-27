
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws.net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN 2400 AND 2410
),
SalesSummary AS (
    SELECT 
        r.web_site_sk,
        r.web_name,
        SUM(r.net_paid) AS total_sales,
        COUNT(r.net_paid) AS transaction_count,
        AVG(r.net_paid) AS avg_sales
    FROM 
        RankedSales r
    WHERE 
        r.rn <= 10
    GROUP BY 
        r.web_site_sk, r.web_name
),
StoreSales AS (
    SELECT 
        ss.store_sk,
        SUM(ss.net_paid) AS store_total_sales,
        COUNT(ss.sale_number) AS store_transaction_count,
        AVG(ss.net_paid) AS store_avg_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.store_sk
),
CombinedSales AS (
    SELECT 
        s.web_site_sk,
        s.web_name,
        s.total_sales,
        s.transaction_count,
        s.avg_sales,
        COALESCE(st.store_total_sales, 0) AS store_total_sales,
        COALESCE(st.store_transaction_count, 0) AS store_transaction_count
    FROM 
        SalesSummary s
    LEFT JOIN 
        StoreSales st ON s.web_site_sk = st.store_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.web_name,
    cs.total_sales,
    cs.transaction_count,
    cs.avg_sales,
    COALESCE(cs.store_total_sales, 0) AS store_total_sales,
    COALESCE(cs.store_transaction_count, 0) AS store_transaction_count
FROM 
    customer c
LEFT JOIN 
    CombinedSales cs ON c.c_current_addr_sk = cs.web_site_sk
WHERE 
    (c.c_birth_year > 1980 AND c.c_birth_year < 1990)
    OR (c.c_first_name LIKE 'A%' AND c.c_last_name IS NOT NULL)
ORDER BY 
    cs.total_sales DESC,
    cs.transaction_count DESC
LIMIT 50;
