WITH SupplierStats AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 

CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(l.l_orderkey) AS line_item_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
)

SELECT r.r_name AS region_name,
       COUNT(DISTINCT ns.n_nationkey) AS total_nations,
       AVG(ss.total_supply_cost) AS avg_supply_cost,
       SUM(co.total_order_value) AS total_order_value,
       MAX(co.line_item_count) AS max_line_items,
       COALESCE(MAX(ss.distinct_parts_supplied), 0) AS max_distinct_parts_supplied
FROM region r 
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN SupplierStats ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN CustomerOrders co ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey) 
WHERE r.r_comment IS NOT NULL 
AND r.r_name LIKE '%East%'
GROUP BY r.r_name
ORDER BY total_order_value DESC;