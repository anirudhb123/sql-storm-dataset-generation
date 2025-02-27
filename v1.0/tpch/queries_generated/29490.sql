WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_container, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(CASE 
            WHEN LENGTH(p.p_name) > 20 THEN 1 
            ELSE 0 
        END) AS long_name_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey
), FilteredParts AS (
    SELECT 
        p.*, 
        RANK() OVER (ORDER BY p.supplier_count DESC) AS rank
    FROM 
        RankedParts p
    WHERE 
        p.long_name_count > 0
)
SELECT 
    fp.p_partkey, 
    fp.p_name, 
    fp.p_brand, 
    fp.p_container, 
    fp.supplier_count, 
    fp.suppliers
FROM 
    FilteredParts fp
WHERE 
    fp.rank <= 10
ORDER BY 
    fp.rank;
