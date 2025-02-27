WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        s.s_comment,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supply_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    spd.supply_info,
    MAX(spd.ps_supplycost) AS max_supply_cost,
    AVG(spd.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(spd.s_comment, '; ') AS aggregated_comments
FROM 
    RankedParts rp
JOIN 
    SupplierPartDetails spd ON rp.p_partkey = spd.p_partkey
WHERE 
    rp.rn <= 3
GROUP BY 
    rp.p_partkey, rp.p_name, rp.p_brand, rp.p_type
ORDER BY 
    rp.p_brand, rp.p_partkey;
