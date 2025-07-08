
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), TotalOrderValue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY o.o_orderkey
), NationalAverage AS (
    SELECT n.n_nationkey, AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
), PartSuppliers AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    GROUP BY ps.ps_partkey
)
SELECT r.r_name, 
       COALESCE(SH.total_supplier_count, 0) AS supplier_count, 
       COALESCE(AVG(NAv.avg_acctbal), 0) AS national_avg_acctbal,
       SUM(COALESCE(TOV.total_value, 0)) AS total_order_value,
       COUNT(DISTINCT ps.ps_partkey) AS unique_parts
FROM region r
LEFT JOIN (
    SELECT n.n_regionkey, COUNT(DISTINCT s.s_suppkey) AS total_supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey
) SH ON r.r_regionkey = SH.n_regionkey
LEFT JOIN NationalAverage NAv ON r.r_regionkey = NAv.n_nationkey
LEFT JOIN TotalOrderValue TOV ON TOV.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    JOIN customer c ON o.o_custkey = c.c_custkey 
    WHERE c.c_mktsegment = 'BUILDING'
)
JOIN PartSuppliers ps ON ps.ps_partkey = (
    SELECT MAX(ps_partkey) 
    FROM partsupp 
    WHERE ps_supplycost = (
        SELECT MIN(ps_supplycost) 
        FROM partsupp 
        WHERE ps_availqty > 10
    )
)
GROUP BY r.r_name, SH.total_supplier_count, NAv.avg_acctbal
ORDER BY r.r_name;
