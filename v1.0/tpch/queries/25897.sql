
WITH string_aggregates AS (
    SELECT 
        p.p_brand,
        SUBSTRING(p.p_name, 1, 5) AS short_name,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        COUNT(DISTINCT ps.ps_partkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_brand, SUBSTRING(p.p_name, 1, 5)
),
region_summary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    sa.p_brand,
    sa.short_name,
    sa.supplier_names,
    sa.supplier_count,
    rs.region_name,
    rs.nation_count,
    rs.nation_names
FROM 
    string_aggregates sa
CROSS JOIN 
    region_summary rs
WHERE 
    sa.supplier_count > 5 
ORDER BY 
    sa.p_brand, rs.region_name;
