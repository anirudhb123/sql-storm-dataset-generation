WITH SupplierSummary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM SupplierSummary s
    WHERE s.total_cost > (SELECT AVG(total_cost) FROM SupplierSummary) AND s.rank_cost <= 5
)
SELECT co.c_custkey, 
       co.c_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT l.l_orderkey) AS total_lines,
       COALESCE(SUM(ss.total_available), 0) AS total_available_parts
FROM CustomerOrders co
JOIN orders o ON co.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN HighValueSuppliers ss ON l.l_suppkey = ss.s_suppkey
WHERE o.o_orderdate >= '2023-01-01' 
      AND o.o_orderdate < '2023-12-31'
GROUP BY co.c_custkey, co.c_name
HAVING total_revenue > 100000
ORDER BY total_revenue DESC;
