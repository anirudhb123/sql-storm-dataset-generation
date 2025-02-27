WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3 AND s.s_suppkey <> sh.s_suppkey
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '1994-01-01' AND '1994-12-31'
    GROUP BY o.o_orderkey
),
part_availability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size IS NOT NULL
    GROUP BY ps.ps_partkey
),
nation_summary AS (
    SELECT n.n_nationkey, COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM nation n
    LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > 0
    GROUP BY n.n_nationkey
),
ranking_orders AS (
    SELECT o.o_orderkey,
           DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT DISTINCT n.n_name, 
       COALESCE(SUM(os.total_price), 0) AS total_order_value,
       COALESCE(pa.total_available, 0) AS total_parts_available,
       COUNT(sh.s_suppkey) AS supplier_count
FROM nation_summary n
LEFT JOIN order_summary os ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = os.o_orderkey)
LEFT JOIN part_availability pa ON pa.ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderkey = os.o_orderkey)
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
WHERE n.cust_count > (SELECT AVG(cust_count) FROM nation_summary) 
  AND n.n_nationkey NOT IN (SELECT n_nationkey FROM nation_summary WHERE cust_count < 5)
GROUP BY n.n_name
HAVING COUNT(DISTINCT os.o_orderkey) > 2
ORDER BY total_order_value DESC, supplier_count
LIMIT 10;
