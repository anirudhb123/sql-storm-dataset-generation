WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_acctbal < sh.s_acctbal
),
total_sales AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2020-01-01' AND o.o_orderstatus = 'F'
    GROUP BY o.o_custkey
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ts.total, DENSE_RANK() OVER (ORDER BY ts.total DESC) AS rnk
    FROM customer c
    JOIN total_sales ts ON c.c_custkey = ts.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
),
nation_summary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           SUM(s.s_acctbal) AS total_acctbal, 
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    n.n_name AS nation_name,
    ns.supplier_count,
    ns.total_acctbal,
    CASE WHEN ns.avg_acctbal IS NULL THEN 'N/A' ELSE ROUND(ns.avg_acctbal, 2) END AS avg_acctbal,
    tc.c_custkey,
    tc.c_name,
    tc.total,
    SH.level AS supplier_level
FROM nation_summary ns
LEFT JOIN top_customers tc ON ns.supplier_count > 0
LEFT JOIN supplier_hierarchy SH ON tc.c_custkey = SH.s_suppkey
WHERE (ns.nation_name IS NOT NULL OR ns.supplier_count IS NOT NULL)
ORDER BY ns.n_name, tc.total DESC
LIMIT 100;
