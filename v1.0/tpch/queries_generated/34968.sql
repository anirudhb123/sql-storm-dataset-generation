WITH RECURSIVE CustomerOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count, 
           AVG(l.l_quantity) AS avg_quantity
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
), FilteredRegions AS (
    SELECT r.r_regionkey, r.r_name
    FROM region r 
    WHERE r.r_comment IS NOT NULL AND r.r_regionkey % 2 = 0
)
SELECT co.o_orderkey, co.o_orderdate, co.c_name, sp.total_revenue,
       sp.order_count, sp.avg_quantity, fr.r_name
FROM CustomerOrders co
LEFT JOIN SupplierPerformance sp ON co.rn = 1
JOIN FilteredRegions fr ON fr.r_regionkey = (SELECT MAX(n.n_regionkey)
                                              FROM nation n
                                              WHERE n.n_nationkey = co.c_custkey % 25)
WHERE co.o_orderdate >= DATE '2023-01-01'
  AND (sp.total_revenue IS NOT NULL OR co.o_orderdate < CURRENT_DATE)
ORDER BY sp.total_revenue DESC, co.o_orderdate ASC
LIMIT 100;
