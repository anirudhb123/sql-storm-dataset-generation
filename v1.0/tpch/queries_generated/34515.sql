WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
FilteredParts AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 10 AND 20
    GROUP BY p.p_partkey
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
)
SELECT pt.p_partkey, 
       p.p_name, 
       COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS revenue,
       sh.level, 
       si.nation
FROM part pt
LEFT JOIN lineitem l ON pt.p_partkey = l.l_partkey
LEFT JOIN FilteredParts fp ON pt.p_partkey = fp.p_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE') 
LEFT JOIN SupplierInfo si ON si.s_suppkey = l.l_suppkey
WHERE (l.l_returnflag = 'N' AND l.l_linestatus = 'F')
  AND (fp.total_cost IS NOT NULL OR l.l_quantity > 0)
GROUP BY pt.p_partkey, p.p_name, sh.level, si.nation
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY revenue DESC
LIMIT 10;
