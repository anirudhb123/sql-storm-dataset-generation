WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, Level + 1
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_nationkey = cte.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 500
),
PartPrice AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
QualifiedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_discount) AS total_discount
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING SUM(l.l_discount) IS NOT NULL
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT s.s_name) AS supplier_count,
    COALESCE(SUM(pp.avg_supplycost * 0.1), 0.00) AS adjusted_avg_supplycost,
    COUNT(qo.o_orderkey) FILTER (WHERE qo.total_discount > 100) AS high_discount_orders,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY AVG(qo.o_totalprice) DESC) AS order_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierCTE cte ON s.s_suppkey = cte.s_suppkey
LEFT JOIN PartPrice pp ON s.s_suppkey = pp.p_partkey
LEFT JOIN QualifiedOrders qo ON qo.o_orderkey = s.s_suppkey
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1 
   AND MAX(CASE WHEN pp.avg_supplycost IS NULL THEN 1 ELSE 0 END) = 0
ORDER BY r.r_name, adjusted_avg_supplycost DESC;
