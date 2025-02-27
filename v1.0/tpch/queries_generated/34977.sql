WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TotalSales AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
FilteredResults AS (
    SELECT DISTINCT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, sr.supp_name
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN (
        SELECT s.s_suppkey, s.s_name AS supp_name
        FROM supplier s
        JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    ) sr ON ps.ps_suppkey = sr.supp_name
    WHERE ps.ps_availqty IS NOT NULL AND p.p_retailprice > 50
)
SELECT fr.p_partkey, fr.p_name, fr.ps_availqty, fr.ps_supplycost, 
       COALESCE(ts.total_sales, 0) AS total_sales,
       ROW_NUMBER() OVER (PARTITION BY fr.p_partkey ORDER BY fr.ps_supplycost DESC) AS supplier_rank
FROM FilteredResults fr
LEFT JOIN TotalSales ts ON fr.p_partkey = ts.c_custkey
WHERE fr.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY fr.p_partkey, supplier_rank;
