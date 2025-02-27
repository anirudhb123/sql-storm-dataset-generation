WITH RECURSIVE supply_costs AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, 1 AS level
    FROM partsupp
    WHERE ps_availqty > 0
    UNION ALL
    SELECT p.ps_partkey, p.ps_suppkey, p.ps_availqty, p.ps_supplycost * 1.05 AS ps_supplycost, level + 1
    FROM partsupp p
    JOIN supply_costs s ON p.ps_partkey = s.ps_partkey AND level < 3
), filtered_orders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 1000 AND c.c_mktsegment IN ('SMALL', 'LARGE')
), ranked_lineitems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM lineitem l
    WHERE l.l_discount > 0.1
)
SELECT p.p_name, 
       SUM(s.ps_supplycost * r.l_quantity) AS total_supply_cost,
       COUNT(DISTINCT fo.o_orderkey) AS total_orders,
       RANK() OVER (ORDER BY SUM(s.ps_supplycost * r.l_quantity) DESC) AS cost_rank
FROM part p
LEFT JOIN supply_costs s ON p.p_partkey = s.ps_partkey
LEFT JOIN ranked_lineitems r ON r.l_partkey = p.p_partkey
LEFT JOIN filtered_orders fo ON fo.o_orderkey = r.l_orderkey
WHERE p.p_size > 10 AND (fo.o_orderdate >= '2023-01-01' OR fo.o_orderdate IS NULL)
GROUP BY p.p_name
HAVING SUM(s.ps_supplycost * r.l_quantity) IS NOT NULL
ORDER BY total_supply_cost DESC, p.p_name;
