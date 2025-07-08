
WITH RankedParts AS (
    SELECT 
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_type,
        COUNT(ps.ps_partkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY AVG(ps.ps_supplycost) ASC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, p.p_type
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_mfgr,
    rp.p_type,
    rp.supplier_count,
    rp.avg_supply_cost,
    rp.supplier_names
FROM 
    RankedParts rp
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_brand, rp.avg_supply_cost DESC;
