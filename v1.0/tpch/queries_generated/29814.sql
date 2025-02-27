WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_comment,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9 ]', '') AS cleaned_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_comment,
    fs.s_name,
    fs.cleaned_comment
FROM 
    RankedParts rp
JOIN 
    FilteredSuppliers fs ON rp.p_partkey % 10 = fs.s_suppkey % 10
WHERE 
    rp.rank <= 5 
ORDER BY 
    rp.p_retailprice DESC, 
    rp.name_length ASC;
