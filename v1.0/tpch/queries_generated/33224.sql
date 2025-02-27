WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        1 AS hierarchy_level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)

    UNION ALL

    SELECT 
        sp.s_suppkey, 
        sp.s_name, 
        sp.s_nationkey,
        sh.hierarchy_level + 1
    FROM 
        supplier sp
    JOIN 
        supplier_hierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE 
        sh.hierarchy_level < 3
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
nation_with_suppliers AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    nh.n_name,
    ns.supplier_count,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(os.total_revenue), 0) DESC) AS revenue_rank
FROM 
    nation_with_suppliers ns
LEFT JOIN 
    order_summary os ON ns.n_name LIKE '%' || ANY (SELECT DISTINCT s_name FROM supplier_hierarchy WHERE hierarchy_level = 2)
LEFT JOIN 
    nation nh ON nh.n_name = ns.n_name
GROUP BY 
    nh.n_name, ns.supplier_count
HAVING 
    ns.supplier_count > 5 AND COALESCE(SUM(os.total_revenue), 0) > 100000
ORDER BY 
    revenue_rank
LIMIT 10;
