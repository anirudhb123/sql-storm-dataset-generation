WITH RankedParts AS (
    SELECT 
        p_name,
        LENGTH(p_name) AS name_length,
        p_comment,
        ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY LENGTH(p_name) DESC) AS rank
    FROM part
),
FilteredParts AS (
    SELECT 
        rp.p_name, 
        rp.p_comment,
        SUBSTRING(rp.p_comment FROM 1 FOR 20) AS short_comment,
        rp.name_length,
        n.n_name AS nation_name,
        s.s_name AS supplier_name
    FROM RankedParts rp
    JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE rp.rank <= 5
)
SELECT 
    fp.nation_name,
    COUNT(fp.p_name) AS popular_parts,
    AVG(fp.name_length) AS avg_name_length,
    STRING_AGG(fp.short_comment, ', ') AS comments_summary
FROM FilteredParts fp
GROUP BY fp.nation_name
HAVING AVG(fp.name_length) > 10
ORDER BY popular_parts DESC;
