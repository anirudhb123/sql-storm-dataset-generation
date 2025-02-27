WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
            SELECT AVG(s_acctbal)
            FROM supplier
            WHERE s_nationkey IN (
                SELECT n.n_nationkey
                FROM nation n
                WHERE n.n_name = 'USA'
            )
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (
            SELECT AVG(s_acctbal)
            FROM supplier
            WHERE s_nationkey = sh.s_nationkey
    )
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT os.o_orderkey, os.total_revenue, 
           RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM OrderSummary os
    WHERE os.total_revenue > 10000
)
SELECT p.p_partkey, p.p_name, p.p_brand, 
       SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
       COUNT(DISTINCT so.o_orderkey) AS order_count,
       MAX(so.total_revenue) AS max_revenue,
       CASE WHEN COUNT(DISTINCT so.o_orderkey) = 0 THEN 'No Orders' ELSE 'Has Orders' END AS order_status
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN HighValueOrders so ON EXISTS (
    SELECT 1 
    FROM lineitem l 
    WHERE l.l_orderkey = so.o_orderkey AND 
          l.l_partkey = p.p_partkey
)
JOIN SupplierHierarchy sh ON sh.s_nationkey = (
    SELECT c.c_nationkey
    FROM customer c
    WHERE c.c_custkey = (
        SELECT o.o_custkey
        FROM orders o
        WHERE o.o_orderkey = so.o_orderkey
    )
)
WHERE p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost > 100)
GROUP BY p.p_partkey, p.p_name, p.p_brand
HAVING total_cost > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
ORDER BY total_cost DESC, max_revenue DESC;
