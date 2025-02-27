WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand, ', Comment: ', p.p_comment) AS detailed_info,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_brand) AS brand_length,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(LOWER(p.p_comment), ' ', '') AS stripped_comment,
        SUBSTRING(p.p_comment, 1, 10) AS comment_excerpt
    FROM 
        part p
    INNER JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    INNER JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
)
SELECT 
    r.r_name,
    COUNT(*) AS part_count,
    SUM(name_length) AS total_name_length,
    AVG(brand_length) AS avg_brand_length,
    MAX(comment_length) AS max_comment_length,
    MIN(comment_length) AS min_comment_length,
    STRING_AGG(detailed_info, '; ') AS all_detailed_info
FROM 
    StringBenchmark sb
INNER JOIN 
    nation n ON sb.p_partkey = n.n_nationkey
INNER JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    part_count DESC;
