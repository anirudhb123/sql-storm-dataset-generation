WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
AvgPartSupply AS (
    SELECT ps.ps_partkey, AVG(ps.ps_availqty) AS avg_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_mktsegment, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F'

    UNION

    SELECT o.o_orderkey, o.o_totalprice, c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus IS NULL
)
SELECT p.p_name, 
       COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
       MAX(a.avg_avail_qty) AS avg_supply,
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN AvgPartSupply a ON p.p_partkey = a.ps_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = (
    SELECT n.n_nationkey
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_suppkey IN (SELECT s_suppkey FROM partsupp WHERE ps_availqty < 10)
    LIMIT 1
)
GROUP BY p.p_name
HAVING COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY total_sales DESC, avg_supply DESC
LIMIT 10;
