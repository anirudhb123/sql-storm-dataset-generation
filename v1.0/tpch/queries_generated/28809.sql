WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_size ASC) AS rank_size
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        rp.p_size,
        rp.p_retailprice
    FROM 
        RankedParts rp
    WHERE 
        rp.rank_price <= 3 AND 
        rp.rank_size <= 3
)
SELECT 
    fp.p_partkey,
    CONCAT('Part: ', fp.p_name, ' - Brand: ', fp.p_brand, ' - Type: ', fp.p_type) AS part_info,
    fp.p_retailprice,
    (SELECT COUNT(DISTINCT ps.s_suppkey) 
     FROM partsupp ps 
     WHERE ps.ps_partkey = fp.p_partkey) AS supplier_count
FROM 
    FilteredParts fp
ORDER BY 
    fp.p_retailprice DESC;
