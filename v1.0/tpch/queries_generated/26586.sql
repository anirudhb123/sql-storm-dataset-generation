WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        rp.ps_supplycost
    FROM 
        RankedParts rp
    JOIN 
        supplier s ON rp.p_partkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rp.rank <= 3
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    STRING_AGG(CONCAT(p_name, ' (', p_brand, ')'), '; ') AS part_details
FROM 
    FilteredParts
GROUP BY 
    region_name, nation_name, supplier_name
ORDER BY 
    region_name, nation_name, supplier_name;
