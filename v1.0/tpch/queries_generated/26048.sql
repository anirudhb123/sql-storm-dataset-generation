WITH DetailedParts AS (
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
        CONCAT(p.p_mfgr, ' ', p.p_name, ' (', p.p_type, ') - ', p.p_comment) AS detailed_description
    FROM 
        part p
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        STRING_AGG(CONCAT(d.p_name, ' - Cost: $', FORMAT(p.ps_supplycost, 2)), '; ') AS supplied_parts
    FROM 
        supplier s
    JOIN 
        partsupp p ON s.s_suppkey = p.ps_suppkey
    JOIN 
        DetailedParts d ON p.ps_partkey = d.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
)
SELECT 
    si.s_name,
    si.s_address,
    si.s_phone,
    si.supplied_parts,
    COUNT(DISTINCT dp.p_partkey) AS unique_parts_count,
    MAX(dp.p_retailprice) AS max_part_price,
    MIN(dp.p_retailprice) AS min_part_price,
    AVG(dp.p_retailprice) AS avg_part_price
FROM 
    SupplierInfo si
JOIN 
    DetailedParts dp ON si.supplied_parts LIKE CONCAT('%', dp.p_name, '%')
GROUP BY 
    si.s_name, si.s_address, si.s_phone
ORDER BY 
    avg_part_price DESC
LIMIT 10;
