WITH RECURSIVE recursive_orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, 1 AS order_level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, ro.order_level + 1
    FROM orders o
    JOIN recursive_orders ro ON o.o_custkey = ro.o_custkey
    WHERE o.o_orderdate > ro.o_orderdate
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_part_summary AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
lineitem_summary AS (
    SELECT l.l_orderkey,
           COUNT(l.l_linenumber) AS line_count,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS total_returns,
           AVG(l.l_discount) AS average_discount
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT cs.c_name, cs.total_spent, coalesce(sps.total_supply_cost, 0) AS supplier_total_cost,
       SUM(ls.line_count) AS total_lines,
       AVG(ls.average_discount) AS avg_discount 
FROM customer_summary cs
LEFT JOIN supplier_part_summary sps ON sps.part_count > 20
LEFT JOIN lineitem_summary ls ON cs.order_count > 5
WHERE cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary)
GROUP BY cs.c_name, cs.total_spent, sps.total_supply_cost
ORDER BY cs.total_spent DESC
LIMIT 10;
