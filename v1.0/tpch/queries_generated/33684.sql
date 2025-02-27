WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_accountbalance, 0 AS level
    FROM supplier s
    WHERE s.s_accountbalance > 10000 -- Base case: suppliers with account balance over 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.s_accountbalance, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey -- Recursive case
    WHERE s.s_accountbalance > sh.s_accountbalance * 0.75
),
RegionSummary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
FrequentParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_quantity) > 1000
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT r.r_name, fs.p_name, os.total_revenue, COALESCE(sh.level, -1) AS supplier_level
FROM RegionSummary r
JOIN FrequentParts fs ON fs.total_quantity > 2000
FULL OUTER JOIN OrderSummary os ON os.revenue_rank = 1
LEFT JOIN SupplierHierarchy sh ON sh.s_name = os.o_custkey
WHERE os.total_revenue IS NOT NULL OR sh.level IS NULL
ORDER BY r.r_name, os.total_revenue DESC, fs.p_name;
