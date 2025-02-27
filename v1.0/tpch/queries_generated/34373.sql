WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 2
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
),
TopProducts AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2022-06-01' AND l.l_shipdate < '2022-07-01'
    GROUP BY l.l_partkey
    ORDER BY total_revenue DESC
    LIMIT 10
),
FinalReport AS (
    SELECT p.p_partkey, p.p_name, tp.total_revenue, sh.s_name, sh.level
    FROM part p
    JOIN TopProducts tp ON p.p_partkey = tp.l_partkey
    LEFT JOIN supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
    LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
)
SELECT fr.p_partkey, fr.p_name, COALESCE(fr.total_revenue, 0) AS revenue,
       COALESCE(fr.s_name, 'No Supplier') AS supplier_name, fr.level
FROM FinalReport fr
WHERE fr.level IS NULL OR fr.level = 1
ORDER BY revenue DESC, fr.p_partkey;
