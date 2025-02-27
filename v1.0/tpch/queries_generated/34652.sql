WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
supplier_performance AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_supplycost) AS total_supply_cost,
           AVG(ps.ps_availqty) AS avg_avail_qty,
           COUNT(DISTINCT l.l_orderkey) AS orders_count
    FROM partsupp ps
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
high_value_orders AS (
    SELECT oh.o_orderkey, oh.o_totalprice, c.c_name, c.c_mktsegment,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY oh.o_totalprice DESC) AS price_rank
    FROM order_hierarchy oh
    JOIN customer c ON oh.o_custkey = c.c_custkey
)
SELECT DISTINCT
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    hp.o_orderkey,
    hp.o_totalprice,
    hp.c_name AS customer_name,
    hp.c_mktsegment AS market_segment,
    sp.total_supply_cost,
    sp.avg_avail_qty
FROM part p
LEFT JOIN supplier_performance sp ON sp.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN high_value_orders hp ON l.l_orderkey = hp.o_orderkey
WHERE (sp.total_supply_cost IS NOT NULL OR s.s_nationkey IS NULL)
AND hp.price_rank <= 5
ORDER BY p.p_name, hp.o_totalprice DESC;
