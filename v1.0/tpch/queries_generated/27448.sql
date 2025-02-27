WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        COUNT(ps.ps_partkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        rp.p_size,
        rp.p_retailprice,
        rp.supplier_count
    FROM 
        RankedParts rp
    WHERE 
        rp.price_rank <= 5
)
SELECT 
    tp.*,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    TopParts tp
JOIN 
    partsupp ps ON tp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    tp.p_partkey, tp.p_name, tp.p_brand, tp.p_type, tp.p_size, tp.p_retailprice, tp.supplier_count
ORDER BY 
    tp.p_retailprice DESC;
