
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.mfgr AS p_mfgr,
        p.brand AS p_brand,
        p.type AS p_type,
        p.size AS p_size,
        p.container AS p_container,
        p.retailprice AS p_retailprice,
        p.comment AS p_comment,
        COUNT(ps.suppkey) AS supplier_count,
        LISTAGG(DISTINCT s.s_name, '; ') WITHIN GROUP (ORDER BY s.s_name) AS suppliers,
        ROW_NUMBER() OVER (PARTITION BY p.brand ORDER BY p.retailprice DESC) AS price_rank
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.mfgr, p.brand, p.type, p.size, p.container, p.retailprice, p.comment
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
