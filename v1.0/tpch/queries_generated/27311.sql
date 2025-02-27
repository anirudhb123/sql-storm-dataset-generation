WITH StringAggregates AS (
    SELECT 
        p.p_brand,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        STRING_AGG(DISTINCT p.p_name, '; ') AS part_names,
        STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        p.p_brand
),
FilteredAggregates AS (
    SELECT 
        sa.p_brand,
        sa.total_suppliers,
        sa.part_names,
        sa.regions_served
    FROM 
        StringAggregates sa
    WHERE 
        sa.total_suppliers > 5
)
SELECT 
    f.p_brand,
    f.total_suppliers,
    f.part_names,
    LENGTH(f.part_names) AS length_of_part_names,
    f.regions_served,
    LENGTH(f.regions_served) AS length_of_regions_served
FROM 
    FilteredAggregates f
ORDER BY 
    f.total_suppliers DESC;
