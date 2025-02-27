
WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s_suppkey,
        s_name,
        s_nationkey,
        s_acctbal,
        1 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > 10000

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        sh.hierarchy_level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (sh.s_acctbal * 0.9)
),
nation_totals AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
best_part AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_retailprice,
    nt.n_name AS nation_name,
    nt.total_acctbal AS nation_total_acctbal,
    sh.hierarchy_level,
    COALESCE(bp.total_supplycost, 0) AS best_supplycost,
    CASE 
        WHEN bp.rn = 1 THEN 'Best' 
        ELSE 'Not best' 
    END AS supply_cost_rank
FROM part p
JOIN best_part bp ON p.p_partkey = bp.ps_partkey
JOIN supplier s ON s.s_suppkey = p.p_partkey
LEFT JOIN nation_totals nt ON nt.supplier_count < 10
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE p.p_retailprice > 50.00 
    AND (sh.hierarchy_level IS NULL OR sh.hierarchy_level <= 3)
ORDER BY nt.total_acctbal DESC, bp.total_supplycost DESC;
