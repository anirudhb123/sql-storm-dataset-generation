WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        r.r_comment
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sp.s_suppkey,
    sp.s_name,
    nd.n_name AS nation_name,
    nd.region_name,
    sp.total_parts,
    sp.part_names
FROM 
    SupplierParts sp
JOIN 
    NationDetails nd ON sp.s_nationkey = nd.n_nationkey
WHERE 
    sp.total_parts > 5
ORDER BY 
    sp.total_parts DESC, 
    sp.s_name;
