WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey
        )
    UNION ALL
    SELECT 
        s2.s_suppkey, 
        s2.s_name, 
        s2.s_acctbal, 
        s2.s_nationkey,
        sh.level + 1
    FROM 
        supplier_hierarchy sh
    JOIN 
        supplier s2 ON sh.s_nationkey = s2.s_nationkey AND sh.s_suppkey <> s2.s_suppkey
    WHERE 
        s2.s_acctbal IS NOT NULL AND 
        s2.s_acctbal < sh.s_acctbal
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
nation_details AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY n.n_nationkey) AS row_num
    FROM 
        nation n
),
region_stats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    ns.nation_count,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    MAX(sh.level) AS max_supplier_level,
    CASE 
        WHEN MAX(sh.level) IS NULL THEN 'No Supplier Hierarchy'
        WHEN MAX(sh.level) > 3 THEN 'Deep Hierarchy'
        ELSE 'Shallow Hierarchy'
    END AS hierarchy_description
FROM 
    region_stats ns
LEFT JOIN 
    order_summary os ON ns.nation_count > os.distinct_parts
LEFT JOIN 
    supplier_hierarchy sh ON ns.total_supplier_balance > (
        SELECT AVG(s_acctbal) FROM supplier
    )
GROUP BY 
    r.r_name, ns.nation_count
HAVING 
    COUNT(DISTINCT ns.total_supplier_balance) NOT IN (0, 1)
ORDER BY 
    total_revenue DESC, r.r_name;
