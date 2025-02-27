
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id,
        COALESCE(cs_total_sales, 0) AS total_sales,
        COALESCE(ss_total_sales, 0) AS store_sales,
        COALESCE(ws_total_sales, 0) AS web_sales,
        COALESCE(cs_total_sales, 0) + COALESCE(ss_total_sales, 0) + COALESCE(ws_total_sales, 0) AS grand_total
    FROM 
        customer c
    LEFT JOIN (
        SELECT 
            cs_bill_customer_sk, 
            SUM(cs_ext_sales_price) AS cs_total_sales
        FROM 
            catalog_sales
        GROUP BY 
            cs_bill_customer_sk
    ) cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN (
        SELECT 
            ss_customer_sk, 
            SUM(ss_ext_sales_price) AS ss_total_sales
        FROM 
            store_sales
        GROUP BY 
            ss_customer_sk
    ) ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk, 
            SUM(ws_ext_sales_price) AS ws_total_sales
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk
    ) ws ON c.c_customer_sk = ws.ws_bill_customer_sk
),
RankedSales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_customer_id,
        sh.total_sales,
        RANK() OVER (ORDER BY sh.grand_total DESC) AS sales_rank
    FROM 
        SalesHierarchy sh
    WHERE 
        sh.grand_total > (SELECT AVG(grand_total) FROM SalesHierarchy)
    UNION ALL
    SELECT 
        sh.c_customer_sk,
        sh.c_customer_id,
        sh.total_sales
    FROM 
        SalesHierarchy sh
    WHERE 
        sh.grand_total IS NULL
)
SELECT 
    r.sales_rank,
    r.c_customer_id,
    COALESCE(r.total_sales, 0) AS total_sales,
    CASE 
        WHEN r.total_sales IS NULL THEN 'No Sales' 
        ELSE 'Has Sales' 
    END AS sales_status
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;

WITH ExpenseData AS (
    SELECT 
        cd_credit_rating,
        COUNT(*) AS customers_count,
        AVG(cd_purchase_estimate) AS avg_purchase,
        SUM(cd_dep_count) AS total_dependent_count
    FROM 
        customer_demographics 
    WHERE 
        cd_marital_status = 'M'
        AND (cd_purchase_estimate IS NOT NULL AND cd_purchase_estimate > 1000)
    GROUP BY 
        cd_credit_rating
)
SELECT 
    ed.cd_credit_rating,
    ed.customers_count,
    ed.avg_purchase,
    ed.total_dependent_count,
    CASE 
        WHEN ed.customers_count >= 50 THEN 'High'
        ELSE 'Low'
    END AS customer_segment
FROM 
    ExpenseData ed
WHERE 
    ed.total_dependent_count IS NOT NULL
ORDER BY 
    ed.avg_purchase DESC, 
    ed.customers_count DESC;
