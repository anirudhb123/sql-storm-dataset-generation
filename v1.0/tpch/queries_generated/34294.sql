WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
MaxOrderPrices AS (
    SELECT o.custkey, MAX(o.o_totalprice) AS max_price
    FROM orders o
    GROUP BY o.custkey
    HAVING COUNT(o.o_orderkey) > 5
),
PartPopularity AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey
),
TopRegions AS (
    SELECT r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY r.r_name
    ORDER BY revenue DESC
    LIMIT 5
)
SELECT p.p_name, p.p_brand, pp.total_available, th.r_name, th.revenue
FROM part p
LEFT JOIN PartPopularity pp ON p.p_partkey = pp.ps_partkey
JOIN TopRegions th ON th.revenue > (SELECT AVG(revenue) FROM TopRegions)
WHERE p.p_retailprice > 100.00
  AND EXISTS (
      SELECT 1
      FROM MaxOrderPrices mop
      WHERE mop.custkey = p.p_partkey
      AND mop.max_price > 5000.00
  )
ORDER BY pp.total_available DESC NULLS LAST, th.revenue DESC;
