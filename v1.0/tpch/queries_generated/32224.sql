WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = 1

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
), 
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS price_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_commitdate IS NULL
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT rh.r_name AS region_name, 
       COUNT(DISTINCT cs.c_custkey) AS customer_count,
       SUM(ss.total_supply_cost) AS total_supply_cost,
       AVG(os.total_price) AS average_order_total
FROM region rh
LEFT JOIN nation_hierarchy nh ON nh.n_regionkey = rh.r_regionkey
LEFT JOIN customer cs ON cs.c_nationkey = nh.n_nationkey
LEFT JOIN supplier_summary ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 0 AND ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
LEFT JOIN order_summary os ON os.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderstatus = 'O'
) 
WHERE rh.r_regionkey IS NOT NULL
GROUP BY rh.r_name
HAVING COUNT(DISTINCT cs.c_custkey) > 3
ORDER BY total_supply_cost DESC;
