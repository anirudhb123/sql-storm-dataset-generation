
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
),
nation_summary AS (
    SELECT n.n_regionkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey, n.n_name
),
part_summary AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT n.n_name, ps.p_name, COUNT(DISTINCT c.c_custkey) AS associated_customers, 
    SUM(COALESCE(l.l_quantity, 0)) AS total_quantity,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn,
    MAX(sh.level) AS supplier_levels
FROM nation n
LEFT JOIN part_summary ps ON n.n_nationkey = ps.p_partkey
LEFT JOIN lineitem l ON l.l_partkey = ps.p_partkey
LEFT JOIN customer_order_summary c ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE n.n_name LIKE 'A%'
GROUP BY n.n_name, ps.p_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_quantity DESC
LIMIT 10;
