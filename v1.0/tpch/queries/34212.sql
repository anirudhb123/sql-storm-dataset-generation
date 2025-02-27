WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_custkey, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_custkey, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year'
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 500000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 10 AND SUM(o.o_totalprice) > 10000
)
SELECT 
    c.c_name, 
    co.total_orders, 
    co.total_spent, 
    si.total_supply_cost 
FROM CustomerOrders co
JOIN SupplierInfo si ON si.total_supply_cost IN (
    SELECT DISTINCT ps.ps_supplycost 
    FROM partsupp ps 
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    WHERE li.l_discount < 0.05 AND li.l_quantity > 10
)
JOIN customer c ON co.c_custkey = c.c_custkey
LEFT JOIN region r ON c.c_nationkey = r.r_regionkey
WHERE r.r_name IS NOT NULL
ORDER BY total_spent DESC, total_orders DESC 
LIMIT 50;