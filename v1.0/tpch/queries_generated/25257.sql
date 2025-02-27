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
        SEC_TO_TIME(SUM(TIME_TO_SEC(TIMEDIFF(NOW(), STR_TO_DATE(p.p_comment, '%Y-%m-%d %H:%i:%s'))))) / COUNT(*)) AS avg_time_diff,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    GROUP BY 
        p.p_partkey, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice
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
        rp.avg_time_diff
    FROM 
        RankedParts rp
    WHERE 
        rp.rn = 1 AND 
        rp.avg_time_diff IS NOT NULL
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_mfgr,
    fp.p_brand,
    CONCAT(fp.p_type, ' (Size: ', fp.p_size, ')') AS type_size,
    fp.p_container,
    fp.p_retailprice,
    fp.avg_time_diff
FROM 
    FilteredParts fp
WHERE 
    fp.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    fp.p_retailprice DESC, 
    fp.p_name ASC
LIMIT 10;
