WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
    
    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_suppkey = sh.s_suppkey
    WHERE sp.s_acctbal IS NOT NULL AND sp.s_acctbal > sh.s_acctbal
),
LatestOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
HighValueOrders AS (
    SELECT lo.o_orderkey, lo.o_orderdate, lo.o_totalprice
    FROM LatestOrders lo
    WHERE lo.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(COALESCE(ps.total_avail_qty, 0)) AS total_available_quantity,
       AVG(COALESCE(lo.o_totalprice, 0)) AS avg_order_value
FROM customer c
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN HighValueOrders lo ON lo.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN PartSuppliers ps ON lo.o_orderkey = ps.ps_partkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY customer_count DESC, total_available_quantity DESC;
