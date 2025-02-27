WITH RECURSIVE StringBenchmarks AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_comment,
        LENGTH(p.p_name) as name_length,
        LENGTH(p.p_comment) as comment_length,
        SUBSTRING(p.p_name FROM 1 FOR 5) as name_substr,
        UPPER(p.p_brand) as brand_upper,
        LOWER(p.p_comment) as comment_lower,
        CONCAT(p.p_name, ' - ', p.p_brand) as name_brand_concat
    FROM 
        part p
), 
RegionNation AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        STRING_AGG(sb.name_brand_concat, '; ') AS combined_strings
    FROM 
        StringBenchmarks sb
    JOIN 
        supplier s ON s.s_suppkey = sb.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    rn.nation_name,
    rn.region_name,
    rn.combined_strings,
    COUNT(rn.combined_strings) as total_entries,
    AVG(sb.name_length) as avg_name_length,
    AVG(sb.comment_length) as avg_comment_length
FROM 
    RegionNation rn
JOIN 
    StringBenchmarks sb ON POSITION(sb.name_substr IN rn.combined_strings) > 0
GROUP BY 
    rn.nation_name, rn.region_name
ORDER BY 
    total_entries DESC, nation_name, region_name;
