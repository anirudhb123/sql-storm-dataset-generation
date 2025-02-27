WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        STRING_AGG(CONCAT(s.s_name, ' (', s.s_acctbal, ')'), ', ') AS suppliers,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC) AS type_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
), FilteredParts AS (
    SELECT 
        p.*, 
        p.p_name || ' - ' || p.p_brand AS formatted_name
    FROM 
        RankedParts p
    WHERE 
        p.supplier_count >= 5 AND p.type_rank <= 10
)

SELECT 
    f.formatted_name, 
    f.supplier_count, 
    f.suppliers 
FROM 
    FilteredParts f
ORDER BY 
    f.supplier_count DESC;
