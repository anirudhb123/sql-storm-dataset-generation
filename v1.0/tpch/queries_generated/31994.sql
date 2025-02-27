WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate) AS order_seq
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT oh.o_orderkey, oh.o_orderdate, oh.c_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY oh.c_nationkey ORDER BY oh.o_orderdate) AS order_seq
    FROM order_hierarchy oh
    JOIN orders o ON oh.o_orderkey < o.o_orderkey
)
SELECT r.r_name AS region_name, n.n_name AS nation_name,
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
       MAX(ps.ps_supplycost) AS max_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
INNER JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY region_name, nation_name;
