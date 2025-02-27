WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           'Top Supplier' AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT(sh.hierarchy_level, ' > ', s.s_name)
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.s_suppkey <> s.s_suppkey
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, 
           COALESCE(MAX(ps.ps_supplycost), 0) AS max_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
high_value_orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING total_value > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING AVG(s.s_acctbal) IS NOT NULL
),
final_selection AS (
    SELECT ph.p_partkey, ph.p_name, 
           ns.n_name AS nation_name, 
           sh.hierarchy_level,
           CASE 
               WHEN ns.supplier_count > 50 THEN 'High Supplier Density'
               ELSE 'Normal Supplier Density'
           END AS density_category
    FROM part_supplier ph
    JOIN nation_stats ns ON ph.max_supplycost > ns.avg_acctbal
    LEFT JOIN supplier_hierarchy sh ON ns.n_nationkey = sh.s_nationkey
    WHERE EXISTS (SELECT 1 
                  FROM high_value_orders ho 
                  WHERE ho.o_orderkey = sh.s_suppkey)
)
SELECT DISTINCT f.p_partkey, f.p_name, f.nation_name, 
       f.hierarchy_level, f.density_category
FROM final_selection f
WHERE LENGTH(f.nation_name) <= 10
ORDER BY f.p_partkey DESC, f.density_category ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
