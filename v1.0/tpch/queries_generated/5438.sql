WITH RECURSIVE supply_chain AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supply_chain sc ON s.s_suppkey <> sc.s_suppkey AND ps.ps_availqty < sc.ps_availqty
)
SELECT sc.s_suppkey, sc.s_name, SUM(sc.ps_supplycost) AS total_supply_cost
FROM supply_chain sc
GROUP BY sc.s_suppkey, sc.s_name
ORDER BY total_supply_cost DESC
LIMIT 10;

WITH recent_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= NOW() - INTERVAL '1 year'
)
SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name, COUNT(li.l_orderkey) AS total_line_items
FROM recent_orders ro
LEFT JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
GROUP BY ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name
ORDER BY total_line_items DESC
LIMIT 5;
