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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_comment) DESC) AS rnk
    FROM 
        part p
),
MaxCommentLength AS (
    SELECT 
        p_brand,
        MAX(LENGTH(p_comment)) AS max_length
    FROM 
        part
    GROUP BY 
        p_brand
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.p_size,
        rp.p_container,
        rp.p_retailprice,
        rp.p_comment,
        mcl.max_length
    FROM 
        RankedParts rp
    JOIN 
        MaxCommentLength mcl ON rp.p_brand = mcl.p_brand
    WHERE 
        LENGTH(rp.p_comment) = mcl.max_length
)
SELECT 
    fp.p_brand,
    STRING_AGG(fp.p_name, ', ') AS part_names,
    COUNT(fp.p_partkey) AS num_parts,
    AVG(fp.p_retailprice) AS avg_price
FROM 
    FilteredParts fp
GROUP BY 
    fp.p_brand
ORDER BY 
    num_parts DESC;
