
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%special%'
),
SupplierRegions AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    sr.nation_name,
    sr.region_name,
    COUNT(DISTINCT sr.s_suppkey) AS supplier_count,
    AVG(rp.p_retailprice) AS avg_price,
    LISTAGG(rp.p_comment, '; ') WITHIN GROUP (ORDER BY rp.p_comment) AS combined_comments
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierRegions sr ON ps.ps_suppkey = sr.s_suppkey
WHERE 
    rp.price_rank <= 5
GROUP BY 
    rp.p_name, rp.p_brand, rp.p_type, sr.nation_name, sr.region_name
ORDER BY 
    avg_price DESC;
