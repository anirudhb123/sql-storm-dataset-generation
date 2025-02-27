WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2022-01-01' 
      AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY l.l_suppkey
),
CustomerRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ts.total_sales,
        s.s_acctbal,
        CASE 
            WHEN ts.total_sales IS NULL THEN 'No Sales'
            WHEN ts.total_sales > 10000 THEN 'High Sales'
            ELSE 'Low Sales'
        END AS sales_category
    FROM supplier s
    LEFT JOIN TotalSales ts ON s.s_suppkey = ts.l_suppkey
),
FinalReport AS (
    SELECT 
        sh.level,
        ss.s_name,
        ss.total_sales,
        ss.sales_category,
        cr.c_name AS top_customer
    FROM SupplierSales ss
    LEFT JOIN SupplierHierarchy sh ON ss.s_suppkey = sh.s_suppkey
    LEFT JOIN CustomerRanking cr ON cr.c_custkey = (SELECT TOP 1 c.c_custkey 
                                                       FROM customer c
                                                       ORDER BY c.c_acctbal DESC)
)
SELECT 
    fr.level,
    fr.s_name,
    COALESCE(fr.total_sales, 0) AS total_sales,
    fr.sales_category,
    COALESCE(fr.top_customer, 'None') AS top_customer 
FROM FinalReport fr
ORDER BY fr.level, fr.total_sales DESC;
