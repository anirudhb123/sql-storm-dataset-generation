WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 100.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE sh.level < 5
),
SalesData AS (
    SELECT 
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY c.c_name
),
NationAggregates AS (
    SELECT 
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    n.n_name,
    na.supplier_count,
    na.avg_balance,
    COALESCE(sd.total_sales, 0) AS total_sales,
    sd.order_count,
    CASE 
        WHEN na.avg_balance IS NULL THEN 'No Suppliers'
        WHEN na.avg_balance > 500 THEN 'High'
        ELSE 'Low'
    END AS balance_category
FROM NationAggregates na
LEFT JOIN SalesData sd ON na.n_name = substr(sd.c_name, 1, 3)
JOIN region r ON na.n_name = r.r_name
LEFT JOIN SupplierHierarchy sh ON r.r_regionkey = sh.s_suppkey
ORDER BY na.n_name, total_sales DESC;
