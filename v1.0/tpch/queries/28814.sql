WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        s.s_name AS supplier_name,
        COUNT(ps.ps_suppkey) AS supplier_count,
        STRING_AGG(s.s_name, ', ') AS supplier_names,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type, s.s_name
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_type,
        rp.supplier_names,
        rp.supplier_count,
        CASE 
            WHEN rp.rank <= 5 THEN 'Top 5' 
            ELSE 'Others' 
        END AS rank_category
    FROM 
        RankedParts rp
)
SELECT 
    fp.rank_category,
    COUNT(fp.p_partkey) AS part_count,
    STRING_AGG(fp.p_name, ', ') AS part_names,
    MAX(fp.supplier_count) AS max_suppliers
FROM 
    FilteredParts fp
GROUP BY 
    fp.rank_category
ORDER BY 
    fp.rank_category;
