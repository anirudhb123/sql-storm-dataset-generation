WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        1 AS hierarchy_level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal * 0.9, 
        s.s_nationkey,
        sh.hierarchy_level + 1
    FROM 
        supplier s
    JOIN 
        supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND sh.hierarchy_level < 3
),
aggregated_orders AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
popular_parts AS (
    SELECT 
        pl.p_partkey,
        COUNT(*) AS part_count
    FROM 
        lineitem l
    JOIN 
        part pl ON l.l_partkey = pl.p_partkey
    WHERE 
        l.l_discount BETWEEN 0.05 AND 0.25
    GROUP BY 
        pl.p_partkey
    HAVING 
        COUNT(*) > 10
    ORDER BY 
        part_count DESC
    LIMIT 5
),
final_selection AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(ao.total_sales) AS regional_sales,
        COALESCE(SUM(sp.s_acctbal), 0) AS supplier_balance,
        STRING_AGG(DISTINCT pp.p_name, ', ') AS popular_parts
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        aggregated_orders ao ON n.n_nationkey = ao.c_nationkey
    LEFT JOIN 
        supplier_hierarchy sp ON n.n_nationkey = sp.s_nationkey
    LEFT JOIN 
        popular_parts pp ON pp.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_supplycost < 30.00)
    GROUP BY 
        r.r_name
)
SELECT 
    r_name,
    nation_count,
    regional_sales,
    supplier_balance,
    SPLIT_PART(popular_parts, ',', 1) AS top_part,
    CASE WHEN regional_sales IS NULL THEN 'No Sales' ELSE 'Sales Available' END AS sales_status
FROM 
    final_selection
WHERE 
    regional_sales > 50000
ORDER BY 
    supplier_balance DESC NULLS LAST;
