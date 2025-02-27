WITH PartDetails AS (
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
        COUNT(ps.ps_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT CASE WHEN s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'N%') THEN s.s_name END, ', ') AS suppliers_from_nations_starting_with_N
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.supplier_count,
    p.suppliers_from_nations_starting_with_N,
    CONCAT('Part: ', p.p_name, ' (', p.p_brand, ') - ', p.p_comment) AS part_description,
    CASE 
        WHEN p.supplier_count > 5 THEN 'High'
        WHEN p.supplier_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS supplier_availability
FROM 
    PartDetails p
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    p.supplier_count DESC, p.p_name;
