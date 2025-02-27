WITH RECURSIVE nation_pairs AS (
    SELECT n1.n_nationkey AS nation1_key, n1.n_name AS nation1_name, n2.n_nationkey AS nation2_key, n2.n_name AS nation2_name 
    FROM nation n1 
    JOIN nation n2 ON n1.n_nationkey <> n2.n_nationkey 
    WHERE CHAR_LENGTH(n1.n_name) >= 5 AND CHAR_LENGTH(n2.n_name) >= 5
), 
supplier_part AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, (ps.ps_supplycost * ps.ps_availqty) AS supply_value,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY (ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty IS NOT NULL AND ps.ps_availqty > 10
), 
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(l.l_linenumber) AS line_count, 
           DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), 
filtered_orders AS (
    SELECT os.o_orderkey, os.total_revenue, os.line_count 
    FROM order_summary os 
    WHERE os.revenue_rank <= 5 
      AND os.total_revenue > 50000
)
SELECT np.nation1_name, np.nation2_name, sp.s_name, 
       COUNT(DISTINCT fo.o_orderkey) AS order_count,
       SUM(sp.supply_value) AS total_supply_value,
       COUNT(sp.suppkey) AS supplier_count,
       AVG(sp.ps_availqty) AS avg_avail_qty
FROM nation_pairs np
LEFT JOIN supplier_part sp ON np.nation1_key = sp.s_suppkey OR np.nation2_key = sp.s_suppkey
JOIN filtered_orders fo ON sp.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = fo.o_orderkey)
WHERE sp.supply_value IS NOT NULL
GROUP BY np.nation1_name, np.nation2_name
HAVING COUNT(DISTINCT fo.o_orderkey) > 0 OR AVG(sp.ps_availqty) > 50
ORDER BY total_supply_value DESC, order_count DESC;
