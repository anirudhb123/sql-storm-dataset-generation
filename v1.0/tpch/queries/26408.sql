WITH String_Agg AS (
    SELECT 
        s.s_name AS supplier_name,
        STRING_AGG(p.p_name, ', ') AS part_names,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_comment LIKE '%important%'
    GROUP BY 
        s.s_name
),
Region_Agg AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    sa.supplier_name,
    sa.part_names,
    sa.order_count,
    ra.region_name,
    ra.nation_count
FROM 
    String_Agg sa
JOIN 
    Region_Agg ra ON ra.nation_count > 5
ORDER BY 
    sa.order_count DESC, ra.nation_count ASC;
