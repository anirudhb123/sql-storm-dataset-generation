WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        CONCAT(p.p_name, ' - ', p.p_brand) AS product_label
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, p.p_type
),
FilteredParts AS (
    SELECT
        rp.p_partkey,
        rp.product_label,
        rp.supplier_count,
        rp.total_supplycost
    FROM 
        RankedParts rp
    WHERE 
        rp.supplier_count > 5 AND rp.total_supplycost > 1000
)
SELECT 
    fp.product_label,
    fp.supplier_count,
    REPLACE(fp.product_label, ' - ', ' | ') AS modified_label,
    LPAD(CAST(fp.total_supplycost AS CHAR), 10, '0') AS formatted_supplycost
FROM 
    FilteredParts fp
ORDER BY 
    fp.supplier_count DESC, fp.total_supplycost ASC;
