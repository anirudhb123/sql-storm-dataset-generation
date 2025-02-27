WITH RECURSIVE supply_chain AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           ps.ps_partkey, 
           ps.ps_availqty, 
           ps.ps_supplycost,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS cost_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT s.s_suppkey, 
           s.s_name, 
           ps.ps_partkey, 
           ps.ps_availqty, 
           ps.ps_supplycost,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS cost_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN supply_chain sc ON s.s_suppkey = sc.s_suppkey
    WHERE ps.ps_availqty > 0 AND sc.cost_rank < 5
),
ranked_orders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT r.n_name AS nation,
       COUNT(DISTINCT sc.s_suppkey) AS supplier_count,
       SUM(sc.ps_supplycost * sc.ps_availqty) AS total_supply_cost,
       AVG(ro.total_price) AS average_order_value
FROM supply_chain sc
LEFT JOIN nation r ON sc.s_nationkey = r.n_nationkey
JOIN ranked_orders ro ON sc.ps_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
) 
GROUP BY r.n_name
HAVING AVG(ro.total_price) > 1000
ORDER BY supplier_count DESC, total_supply_cost DESC;
