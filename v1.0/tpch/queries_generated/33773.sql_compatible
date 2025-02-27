
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, s_acctbal, 
           CAST(s_name AS VARCHAR(255)) AS path
    FROM supplier
    WHERE s_nationkey IS NOT NULL

    UNION ALL

    SELECT sp.s_nationkey, sp.s_suppkey, sp.s_name, sp.s_acctbal, 
           CONCAT(sh.path, ' -> ', sp.s_name)
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_suppkey <> sh.s_suppkey
),
AggregatedOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY o.o_orderkey
),
HighestRevenue AS (
    SELECT ROW_NUMBER() OVER (ORDER BY a.total_revenue DESC) AS rnk, a.o_orderkey, a.total_revenue
    FROM AggregatedOrders a
)
SELECT DISTINCT n.n_name, 
       p.p_name, 
       COUNT(ps.ps_suppkey) AS supplier_count,
       SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS fulfilled_orders,
       MAX(rs.total_revenue) AS max_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = n.n_nationkey
    ORDER BY c.c_acctbal DESC
    LIMIT 1
)
LEFT JOIN HighestRevenue rs ON rs.o_orderkey = o.o_orderkey
WHERE p.p_size > 10 
  AND ps.ps_availqty IS NOT NULL
  AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
GROUP BY n.n_name, p.p_name
HAVING COUNT(ps.ps_suppkey) > 5 AND MAX(rs.total_revenue) IS NOT NULL
ORDER BY n.n_name, p.p_name DESC;
