WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size
),
PopularParts AS (
    SELECT 
        r.r_name AS region_name, 
        rp.p_type, 
        rp.p_brand, 
        rp.supplier_count
    FROM 
        RankedParts rp
    JOIN 
        supplier s ON rp.supplier_count > 1
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rp.total_available_quantity > 100
)
SELECT 
    region_name, 
    p_type, 
    p_brand, 
    COUNT(*) AS popular_parts_count
FROM 
    PopularParts
GROUP BY 
    region_name, p_type, p_brand
ORDER BY 
    region_name, popular_parts_count DESC;
