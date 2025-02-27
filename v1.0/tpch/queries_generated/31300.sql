WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
), 

PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
), 

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000.00
)

SELECT r.r_name, 
       COUNT(DISTINCT co.o_orderkey) AS total_orders,
       SUM(co.o_totalprice) AS total_revenue,
       AVG(p.ps_supplycost) AS avg_supply_cost,
       MAX(ph.level) AS max_order_level
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN PartSupplier p ON s.s_suppkey = p.ps_suppkey AND p.rn = 1
LEFT JOIN CustomerOrders co ON s.s_suppkey = co.c_custkey
LEFT JOIN OrderHierarchy ph ON co.o_orderkey = ph.o_orderkey
WHERE r.r_name IS NOT NULL
  AND p.p_partkey IS NOT NULL
  AND (co.o_totalprice IS NULL OR co.o_totalprice > 5000)
GROUP BY r.r_name
HAVING COUNT(co.o_orderkey) > 10
ORDER BY total_revenue DESC;
