WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        LENGTH(p.p_comment) > 10
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000 
        AND UPPER(s.s_comment) LIKE '%RELIABILITY%'
),
FinalResults AS (
    SELECT 
        rp.p_name,
        rp.p_mfgr,
        fs.s_name,
        fs.comment_length
    FROM 
        RankedParts rp
    JOIN 
        FilteredSuppliers fs ON rp.p_partkey = (
            SELECT ps.ps_partkey
            FROM partsupp ps
            WHERE ps.ps_supplycost = (
                SELECT MIN(ps2.ps_supplycost)
                FROM partsupp ps2
                WHERE ps2.ps_partkey = rp.p_partkey
            )
            LIMIT 1
        )
    WHERE 
        rp.rn <= 5
)
SELECT 
    f.p_name,
    f.p_mfgr,
    f.s_name,
    f.comment_length,
    CONCAT('Part: ', f.p_name, ' | Supplier: ', f.s_name, ' | Comment Length: ', f.comment_length) AS info
FROM 
    FinalResults f
ORDER BY 
    f.comment_length DESC;
