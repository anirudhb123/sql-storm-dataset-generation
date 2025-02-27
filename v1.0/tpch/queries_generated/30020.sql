WITH RECURSIVE orders_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders_hierarchy oh
    JOIN orders o ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'F'
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
lineitem_grouped AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < CURRENT_DATE
    GROUP BY l.l_partkey
),
final_report AS (
    SELECT p.p_partkey, p.p_name, 
           COALESCE(ls.total_sales, 0) AS total_sales, 
           COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
           (COALESCE(ls.total_sales, 0) - COALESCE(ss.total_supply_cost, 0)) AS profit_margin,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    LEFT JOIN lineitem_grouped ls ON p.p_partkey = ls.l_partkey
    LEFT JOIN supplier_stats ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = p.p_partkey
    )
)
SELECT r.r_name,
       AVG(fr.profit_margin) AS avg_profit_margin,
       COUNT(fr.p_partkey) AS part_count
FROM final_report fr
JOIN region r ON r.r_regionkey = (
    SELECT n.n_regionkey
    FROM nation n
    JOIN customer c ON c.c_nationkey = n.n_nationkey
    WHERE c.c_custkey IN (
        SELECT o.o_custkey
        FROM orders o
        WHERE o.o_orderkey IN (SELECT oh.o_orderkey FROM orders_hierarchy oh)
    )
)
GROUP BY r.r_name
HAVING AVG(fr.profit_margin) > 0
ORDER BY avg_profit_margin DESC
LIMIT 10;
