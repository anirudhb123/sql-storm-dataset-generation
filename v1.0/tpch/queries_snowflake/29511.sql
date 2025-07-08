WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
FilteredParts AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY p_brand ORDER BY supplier_count DESC) AS brand_rank
    FROM 
        RankedParts
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_mfgr,
    fp.p_brand,
    fp.p_type,
    fp.p_size,
    fp.p_container,
    fp.p_retailprice,
    fp.p_comment,
    fp.supplier_count,
    r.r_name AS region_name
FROM 
    FilteredParts fp
JOIN 
    supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = fp.p_partkey LIMIT 1)
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    fp.brand_rank <= 5
ORDER BY 
    fp.p_brand, fp.supplier_count DESC;
