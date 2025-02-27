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
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS combined_info,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_upper,
        LOWER(p.p_name) AS name_lower,
        REPLACE(p.p_comment, 'special', 'standard') AS modified_comment
    FROM
        part p
)
SELECT
    sb.combined_info,
    COUNT(*) AS num_parts,
    AVG(sb.name_length) AS avg_name_length,
    STRING_AGG(DISTINCT sb.name_upper, ', ') AS unique_upper_names,
    STRING_AGG(DISTINCT sb.modified_comment, '; ') AS unique_comments
FROM
    StringBenchmark sb
JOIN
    partsupp ps ON sb.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE
    s.s_acctbal > 1000.00
GROUP BY
    sb.combined_info
ORDER BY
    num_parts DESC
LIMIT 10;
