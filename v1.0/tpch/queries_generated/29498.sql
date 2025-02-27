WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        STRING_AGG(CONCAT(s.s_name, ' (', s.s_phone, ')'), ', ') AS supplier_details
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
        *,
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY total_avail_qty DESC) AS rank
    FROM 
        RankedParts
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_mfgr,
    fp.p_brand,
    fp.p_type,
    fp.supplier_count,
    fp.total_avail_qty,
    fp.supplier_details
FROM 
    FilteredParts fp
WHERE 
    fp.rank <= 5
ORDER BY 
    fp.p_brand, fp.total_avail_qty DESC;
