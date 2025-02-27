WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        COUNT(ps.ps_partkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        STRING_AGG(DISTINCT CONCAT(s.s_address, ' (', s.s_phone, ')'), '; ') AS supplier_details
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
),
SelectedParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.supplier_count,
        rp.total_avail_qty,
        rp.supplier_names,
        rp.supplier_details,
        ROW_NUMBER() OVER (ORDER BY rp.total_avail_qty DESC) AS rn
    FROM 
        RankedParts rp
)
SELECT 
    sp.p_partkey,
    sp.p_name,
    sp.p_mfgr,
    sp.supplier_count,
    sp.total_avail_qty,
    sp.supplier_names,
    sp.supplier_details
FROM 
    SelectedParts sp
WHERE 
    sp.rn <= 10
ORDER BY 
    sp.total_avail_qty DESC;
