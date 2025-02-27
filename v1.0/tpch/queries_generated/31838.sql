WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
AvgPrice AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
),
TotalRevenue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_shipdate < CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey
),
RankedOrders AS (
    SELECT o.o_orderkey, tr.total_revenue,
           RANK() OVER (ORDER BY tr.total_revenue DESC) AS revenue_rank
    FROM TotalRevenue tr
    JOIN orders o ON tr.o_orderkey = o.o_orderkey
)
SELECT s.s_name AS supplier_name,
       p.p_name AS part_name,
       r.r_name AS region_name,
       SUM(l.l_quantity) AS total_quantity,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       MAX(oh.revenue_rank) AS highest_revenue_rank
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN RankedOrders oh ON o.o_orderkey = oh.o_orderkey
WHERE (p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) OR p.p_size IS NULL)
  AND s.s_acctbal IS NOT NULL
GROUP BY s.s_name, p.p_name, r.r_name
HAVING SUM(l.l_quantity) > 1000
ORDER BY total_sales DESC, s.s_name ASC;
