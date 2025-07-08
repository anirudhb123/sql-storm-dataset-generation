WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(*) AS supplier_count, AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
part_supplier_counts AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    ps.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    COALESCE(ps.supplier_count, 0) AS supplier_count,
    (SELECT COUNTS.total_spend
     FROM (SELECT COUNT(*) AS total_spend FROM orders o WHERE o.o_orderstatus = 'F') AS COUNTS) AS total_filled_orders,
    ns.avg_acctbal
FROM part p
LEFT JOIN part_supplier_counts ps ON p.p_partkey = ps.p_partkey
CROSS JOIN nation_stats ns
WHERE (p.p_size BETWEEN 10 AND 15 OR p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)) 
  AND (p.p_comment IS NOT NULL AND p.p_comment NOT LIKE '%fragile%')
ORDER BY total_filled_orders DESC, avg_acctbal ASC
LIMIT 100;
