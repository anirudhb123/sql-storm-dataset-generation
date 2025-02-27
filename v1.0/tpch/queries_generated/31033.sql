WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 4
),
order_totals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
final_report AS (
    SELECT r.r_name, n.n_name, c.c_name, SUM(ot.total) AS total_sales, 
           COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
           STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN order_totals ot ON c.c_custkey = ot.o_orderkey
    LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
    LEFT JOIN part_supplier_info psi ON psi.rn = 1
    LEFT JOIN part p ON psi.p_partkey = p.p_partkey
    WHERE r.r_name IS NOT NULL
    GROUP BY r.r_name, n.n_name, c.c_name
)
SELECT fr.r_name, fr.n_name, fr.c_name, fr.total_sales, 
       COALESCE(fr.supplier_count, 0) AS supplier_count, 
       COALESCE(fr.part_names, 'None') AS part_names 
FROM final_report fr
WHERE fr.total_sales > (SELECT AVG(total) FROM order_totals)
ORDER BY fr.total_sales DESC
LIMIT 10;
