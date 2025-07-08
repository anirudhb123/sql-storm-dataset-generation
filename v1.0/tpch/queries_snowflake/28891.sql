
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
), FilteredParts AS (
    SELECT 
        rp.*,
        RANK() OVER (ORDER BY rp.total_supply_cost DESC) AS rank
    FROM 
        RankedParts rp
    WHERE 
        rp.supplier_count >= 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    SUBSTR(p.p_comment, 1, 10) AS truncated_comment,
    p.p_type,
    fp.supplier_count,
    fp.total_supply_cost,
    fp.supplier_names
FROM 
    part p
JOIN 
    FilteredParts fp ON p.p_partkey = fp.p_partkey
WHERE 
    p.p_size BETWEEN 1 AND 20
ORDER BY 
    fp.rank, p.p_partkey;
