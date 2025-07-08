
WITH RankedParts AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_type,
        p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) AS rn
    FROM 
        part
    WHERE 
        p_name LIKE '%special%'
),
SupplierWithDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation,
        r.r_name AS supplier_region,
        s.s_acctbal,
        s.s_phone,
        LISTAGG(DISTINCT rp.p_name, ', ') WITHIN GROUP (ORDER BY rp.p_name) AS supplied_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name, r.r_name, s.s_acctbal, s.s_phone
)
SELECT 
    swd.s_suppkey,
    swd.s_name,
    swd.s_address,
    swd.supplier_nation,
    swd.supplier_region,
    swd.s_acctbal,
    swd.s_phone,
    COUNT(swd.supplied_parts) AS part_count,
    MAX(CASE WHEN rp.rn = 1 THEN rp.p_retailprice END) AS max_part_price,
    MIN(CASE WHEN rp.rn = 1 THEN rp.p_retailprice END) AS min_part_price
FROM 
    SupplierWithDetails swd
LEFT JOIN 
    RankedParts rp ON swd.supplied_parts LIKE '%' || rp.p_name || '%'
GROUP BY 
    swd.s_suppkey, swd.s_name, swd.s_address, swd.supplier_nation, swd.supplier_region, swd.s_acctbal, swd.s_phone
ORDER BY 
    part_count DESC, max_part_price DESC
LIMIT 10;
