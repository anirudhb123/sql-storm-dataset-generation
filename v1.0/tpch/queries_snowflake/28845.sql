WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(CASE WHEN LENGTH(p.p_comment) > 0 THEN 1 ELSE 0 END) AS comment_exists,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_per_brand
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
), 
TopRankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.supplier_count,
        p.comment_exists
    FROM 
        RankedParts p
    WHERE 
        p.rank_per_brand <= 5
)

SELECT 
    t.p_partkey,
    CONCAT(t.p_name, ' - ', t.p_mfgr, ' [', t.supplier_count, ' suppliers]') AS part_details,
    CASE 
        WHEN t.comment_exists > 0 THEN 'Comment Available'
        ELSE 'No Comment'
    END AS comment_status
FROM 
    TopRankedParts t
JOIN 
    supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = t.p_partkey LIMIT 1)
ORDER BY 
    t.p_brand, t.supplier_count DESC;
