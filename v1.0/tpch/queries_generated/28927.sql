WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        COUNT(ps.ps_availqty) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
DetailedParts AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        rp.supplier_count,
        rp.supplier_names,
        CASE
            WHEN rp.supplier_count > 5 THEN 'High'
            WHEN rp.supplier_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS supplier_availablity
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    d.region_name,
    d.nation_name,
    d.p_partkey,
    d.p_name,
    d.p_brand,
    d.p_type,
    d.supplier_count,
    d.supplier_names,
    d.supplier_availablity
FROM 
    DetailedParts d
WHERE 
    d.supplier_availablity = 'High'
ORDER BY 
    d.region_name, d.nation_name, d.p_partkey;
