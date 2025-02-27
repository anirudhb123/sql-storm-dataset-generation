WITH RankedParts AS (
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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.p_type) AS total_parts
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20)
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal >= (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey IN (
                SELECT n.n_nationkey 
                FROM nation n 
                WHERE n.n_comment LIKE '%special%'
            )
        )
)
SELECT 
    p.p_name,
    p.p_retailprice,
    s.s_name,
    COALESCE(s2.s_name, 'No Supplier') AS alternate_supplier,
    p.total_parts,
    CASE 
        WHEN p.total_parts > 5 THEN 'High Variety'
        ELSE 'Limited Variety' 
    END AS variety_status
FROM 
    RankedParts p
LEFT JOIN 
    FilteredSuppliers s ON s.rn = 1 AND s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey
    )
LEFT JOIN 
    supplier s2 ON s2.s_suppkey = (SELECT MIN(ps2.ps_suppkey) FROM partsupp ps2 WHERE ps2.ps_partkey = p.p_partkey AND ps2.ps_availqty > 0)
WHERE 
    p.rn <= 3
    AND (p.p_comment IS NULL OR p.p_comment NOT LIKE '%damaged%')
ORDER BY 
    p.p_retailprice DESC, s.s_name ASC;
