WITH SupplierParts AS (
    SELECT 
        s.s_name, 
        p.p_name, 
        p.p_brands, 
        p.p_retailprice, 
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        CONCAT(s.s_name, ' - ', p.p_name) AS combined_name
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedData AS (
    SELECT 
        s_name, 
        COUNT(DISTINCT p_name) AS part_count,
        AVG(p_retailprice) AS avg_price,
        STRING_AGG(short_comment, '; ') AS comment_summary
    FROM 
        SupplierParts
    GROUP BY 
        s_name
)
SELECT 
    s_name, 
    part_count, 
    avg_price,
    UPPER(comment_summary) AS upper_comments, 
    REPLACE(combined_name, ' - ', ': ') AS formatted_combined_name
FROM 
    SupplierParts ps
JOIN 
    AggregatedData ad ON ps.s_name = ad.s_name
WHERE 
    part_count > 5 
ORDER BY 
    avg_price DESC, s_name;
