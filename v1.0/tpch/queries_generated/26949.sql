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
        COUNT(ps.ps_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, '; ') AS suppliers,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
FilteredParts AS (
    SELECT 
        rp.*,
        REPLACE(rp.p_comment, 'good', 'excellent') AS modified_comment
    FROM 
        RankedParts rp
    WHERE 
        supplier_count > 1 AND price_rank <= 10
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_mfgr,
    fp.suppliers,
    fp.modified_comment,
    LENGTH(fp.modified_comment) AS comment_length
FROM 
    FilteredParts fp
ORDER BY 
    fp.p_retailprice DESC;
