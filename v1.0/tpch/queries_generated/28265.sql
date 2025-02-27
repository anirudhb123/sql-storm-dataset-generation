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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
),
PopularSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        COUNT(ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
    HAVING 
        COUNT(ps.ps_partkey) > 50
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ps.s_name AS supplier_name,
    ps.s_address AS supplier_address,
    ps.total_parts
FROM 
    RankedParts rp
JOIN 
    PopularSuppliers ps ON rp.p_partkey IN (
        SELECT 
            ps_partkey 
        FROM 
            partsupp 
        WHERE 
            ps_suppkey = ps.s_suppkey
    )
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
