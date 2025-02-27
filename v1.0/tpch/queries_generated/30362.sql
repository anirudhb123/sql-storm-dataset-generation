WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, s2.s_acctbal, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s2.s_nationkey
    WHERE sh.level < 5
),

OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),

PartRevenue AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice - l.l_discount) AS part_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)

SELECT r.r_name, 
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       SUM(COALESCE(os.total_revenue, 0)) AS total_order_revenue,
       MAX(pr.part_revenue) AS max_part_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN OrderStats os ON os.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderdate > DATE '2023-01-01'
)
LEFT JOIN PartRevenue pr ON pr.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps
    WHERE ps.ps_availqty > 100
)
GROUP BY r.r_name
ORDER BY r.r_name DESC;
