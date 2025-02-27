WITH RECURSIVE sup_quantity AS (
    SELECT ps_partkey, 
           SUM(ps_availqty) AS total_avail_qty
    FROM partsupp
    GROUP BY ps_partkey
), 
recent_orders AS (
    SELECT o_custkey, 
           COUNT(o_orderkey) AS order_count, 
           SUM(o_totalprice) AS total_revenue
    FROM orders
    WHERE o_orderdate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY o_custkey
), 
high_value_cust AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COALESCE(r.total_revenue, 0) AS total_revenue
    FROM customer c
    LEFT JOIN recent_orders r ON c.c_custkey = r.o_custkey
    WHERE COALESCE(r.total_revenue, 0) > 10000
)
SELECT n.n_name, 
       r.r_name, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
       AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
       MAX(COALESCE(p.p_retailprice, 0)) AS max_part_retailprice,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM nation n
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN lineitem l ON s.s_suppkey = l.l_suppkey 
JOIN part p ON l.l_partkey = p.p_partkey
LEFT JOIN high_value_cust hvc ON s.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = p.p_partkey)
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN sup_quantity sq ON p.p_partkey = sq.ps_partkey
WHERE l.l_shipdate >= (CURRENT_DATE - INTERVAL '30 days')
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5 
   AND MAX(COALESCE(l.l_quantity, 0)) < (SELECT AVG(l2.l_quantity) FROM lineitem l2)
ORDER BY avg_order_value DESC NULLS LAST;
