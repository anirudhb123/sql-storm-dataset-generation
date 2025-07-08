
WITH RECURSIVE supply_chain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty,
           ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
), ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS cust_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_custkey
), high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (
          SELECT AVG(c2.c_acctbal) FROM customer c2
          WHERE c2.c_mktsegment = c.c_mktsegment
    )
)
SELECT p.p_partkey, p.p_name, r.r_name AS region_name, SUM(l.l_quantity) AS total_quantity,
       MAX(l.l_extendedprice) AS max_price, AVG(l.l_discount) AS avg_discount,
       CASE 
           WHEN SUM(l.l_quantity) IS NULL THEN 'No Sales'
           ELSE 'Sales Achieved'
       END AS sales_status
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
AND p.p_size BETWEEN 10 AND 30
AND EXISTS (
    SELECT 1 FROM high_value_customers hvc
    WHERE hvc.c_custkey = (
        SELECT o.o_custkey
        FROM ranked_orders o
        WHERE o.o_orderkey = l.l_orderkey
        FETCH FIRST 1 ROW ONLY
    )
)
GROUP BY p.p_partkey, p.p_name, r.r_name
HAVING SUM(l.l_quantity) > (
    SELECT COUNT(*)
    FROM supply_chain
    WHERE ps_partkey = p.p_partkey AND rank <= 3
)
ORDER BY total_quantity DESC, max_price ASC;
