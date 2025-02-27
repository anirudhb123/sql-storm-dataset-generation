
WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(
            SUBSTRING(p.p_name, 1, 10), 
            ' - ', 
            SUBSTRING(p.p_comment, 1, 10),
            ' - ', 
            REPLACE(p.p_type, ' ', '_'),
            ' - Brand: ', 
            p.p_brand
        ) AS formatted_string
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        LENGTH(p.p_name) > 5 AND 
        s.s_acctbal > 2000
), FinalAggregation AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT sa.p_partkey) AS part_count,
        STRING_AGG(sa.formatted_string, '; ') AS aggregated_strings
    FROM 
        StringAggregation sa
    JOIN 
        nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = sa.p_partkey)
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    region_name, 
    part_count, 
    aggregated_strings
FROM 
    FinalAggregation
ORDER BY 
    part_count DESC, region_name;
