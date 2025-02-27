WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal < (SELECT MIN(s_acctbal) FROM supplier WHERE s.s_nationkey = sh.s_nationkey)
),
parts_stats AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_availqty, SUM(ps.ps_supplycost) AS total_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           MAX(o.o_totalprice) AS max_order_price,
           STRING_AGG(o.o_orderstatus || ' - ' || TO_CHAR(o.o_orderdate, 'YYYY-MM-DD'), '; ') AS order_details
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
nation_region AS (
    SELECT n.n_name, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 5
)
SELECT ps.p_partkey, ps.p_name, ps.supplier_count, ps.total_availqty, ps.total_supplycost,
       co.order_count, co.max_order_price, co.order_details,
       nr.n_name, nr.r_name, nr.supplier_count AS region_supplier_count,
       sh.level AS supplier_level
FROM parts_stats ps
JOIN customer_orders co ON ps.supplier_count = co.order_count
LEFT JOIN nation_region nr ON nr.supplier_count > ps.supplier_count
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_acctbal <= co.max_order_price)
WHERE ps.total_supplycost IS NOT NULL
  AND (ps.total_availqty BETWEEN 10 AND 100 OR co.order_count > 0)
ORDER BY ps.total_supplycost DESC NULLS LAST;
