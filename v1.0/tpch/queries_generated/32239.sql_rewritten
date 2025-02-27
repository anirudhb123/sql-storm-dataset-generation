WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = s.s_nationkey)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.hierarchy_level < 3
),

part_totals AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY p.p_partkey
),

nation_totals AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),

ranked_parts AS (
    SELECT pt.p_partkey, pt.total_sales, ROW_NUMBER() OVER (ORDER BY pt.total_sales DESC) AS sales_rank
    FROM part_totals pt
    WHERE pt.total_sales > 10000
),

final_report AS (
    SELECT 
        r.r_name,
        nt.n_name,
        COUNT(DISTINCT su.s_suppkey) AS num_suppliers,
        SUM(pt.total_sales) AS total_sales,
        MAX(COALESCE(su.s_acctbal, 0)) AS max_supplier_acctbal
    FROM region r
    FULL OUTER JOIN nation_totals nt ON r.r_regionkey = nt.n_nationkey
    LEFT JOIN supplier su ON nt.n_nationkey = su.s_nationkey
    LEFT JOIN ranked_parts pt ON pt.p_partkey = su.s_nationkey
    GROUP BY r.r_name, nt.n_name
)

SELECT *
FROM final_report
WHERE total_sales IS NOT NULL AND num_suppliers > 0
ORDER BY total_sales DESC;