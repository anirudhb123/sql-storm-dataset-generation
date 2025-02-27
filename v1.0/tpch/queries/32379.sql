
WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_custkey, 1 AS level
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderdate, c.c_custkey, oh.level + 1
    FROM order_hierarchy oh
    JOIN orders o ON o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderkey < oh.o_orderkey)
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
total_sales AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS ranking
    FROM lineitem l
    GROUP BY l.l_orderkey
),
supplier_stats AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS total_customers, 
       SUM(ts.total) AS total_sales_amount, 
       AVG(ss.supply_cost) AS average_supply_cost, 
       MAX(ss.part_count) AS max_part_per_supplier
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN total_sales ts ON c.c_custkey = ts.l_orderkey
LEFT JOIN supplier_stats ss ON c.c_nationkey = ss.s_suppkey
GROUP BY r.r_name
HAVING SUM(ts.total) IS NOT NULL
ORDER BY total_sales_amount DESC;
