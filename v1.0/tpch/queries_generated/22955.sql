WITH RECURSIVE price_calc AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, 
           ps_supplycost + (SELECT AVG(ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = ps_partkey) AS adjusted_cost
    FROM partsupp
    WHERE ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
    UNION ALL
    SELECT p.ps_partkey, p.ps_suppkey, p.ps_availqty, p.ps_supplycost,
           p.ps_supplycost + (SELECT AVG(ps_supplycost) FROM partsupp ps3 WHERE ps3.ps_partkey = p.ps_partkey) * 1.1
    FROM partsupp p
    JOIN price_calc pc ON p.ps_partkey = pc.ps_partkey
    WHERE pc.adjusted_cost < p.ps_supplycost
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM orders o
    WHERE o.o_orderstatus = 'F'
),
customer_details AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
)
SELECT r.r_name,
       SUM(COALESCE(pc.adjusted_cost, 0)) AS total_adjusted_cost,
       AVG(od.o_totalprice) AS avg_order_price,
       COUNT(DISTINCT cd.c_custkey) AS active_customers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN price_calc pc ON s.s_suppkey = pc.ps_suppkey
LEFT JOIN lineitem l ON pc.ps_partkey = l.l_partkey
LEFT JOIN ranked_orders od ON l.l_orderkey = od.o_orderkey
LEFT JOIN customer_details cd ON od.o_orderkey = cd.c_custkey
WHERE r.r_name NOT LIKE '%East%'
  AND cd.customer_rank IS NOT NULL
  AND EXISTS (SELECT 1 FROM lineitem l2 WHERE l2.l_returnflag = 'R' AND l2.l_orderkey = l.l_orderkey)
GROUP BY r.r_name
HAVING SUM(pc.adjusted_cost) > 1000
ORDER BY total_adjusted_cost DESC, r.r_name ASC;
