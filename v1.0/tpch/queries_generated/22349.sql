WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 2
),
nation_totals AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS total_order_value
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY n.n_nationkey, n.n_name
),
part_statistics AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           SUM(ps.ps_availqty) AS total_available_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
composite_results AS (
    SELECT n.n_name, ns.total_order_value, ps.p_partkey, ps.supplier_count, ps.avg_supply_cost,
           CASE WHEN ps.total_available_qty IS NULL THEN 'NA' ELSE CAST(ps.total_available_qty AS VARCHAR) END AS total_available_qty_str
    FROM nation_totals ns
    LEFT JOIN part_statistics ps ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')
    WHERE (ns.total_order_value IS NOT NULL AND ps.supplier_count > 0) 
      OR (ps.avg_supply_cost IS NOT NULL AND ns.total_order_value <= 10000)
),
final_results AS (
    SELECT cr.n_name, cr.total_order_value, cr.p_partkey, cr.supplier_count, cr.avg_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY cr.n_name ORDER BY cr.total_order_value DESC NULLS LAST) AS rank,
           (CASE
               WHEN cr.total_order_value > 10000 THEN 'High'
               WHEN cr.total_order_value IS NULL THEN 'Missing'
               ELSE 'Moderate'
           END) AS order_bracket
    FROM composite_results cr
    WHERE cr.total_order_value IS NOT NULL OR cr.supplier_count IS NOT NULL
)
SELECT fr.n_name, fr.p_partkey, fr.supplier_count, fr.avg_supply_cost, fr.order_bracket
FROM final_results fr
WHERE fr.rank <= 5
ORDER BY fr.n_name, fr.supplier_count DESC, fr.avg_supply_cost ASC;
