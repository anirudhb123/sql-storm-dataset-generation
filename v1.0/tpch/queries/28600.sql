
WITH StringAggregation AS (
    SELECT 
        p.p_partkey, 
        MIN(s.s_name) AS min_supplier_name, 
        MAX(s.s_name) AS max_supplier_name, 
        STRING_AGG(DISTINCT s.s_name, ', ') AS all_supplier_names,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey
),
FilteredRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        CHAR_LENGTH(r.r_comment) AS comment_length
    FROM 
        region r
    WHERE 
        r.r_name LIKE 'A%'
),
FinalReport AS (
    SELECT 
        sa.p_partkey,
        sa.all_supplier_names,
        fr.r_name AS region_name,
        fr.comment_length,
        CONCAT('Part ', sa.p_partkey, ' has suppliers: ', sa.all_supplier_names, ' in region ', fr.r_name) AS report
    FROM 
        StringAggregation sa
    JOIN 
        nation n ON n.n_nationkey = (SELECT MIN(s_nationkey) FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey WHERE ps.ps_partkey = sa.p_partkey)
    JOIN 
        FilteredRegions fr ON fr.r_regionkey = n.n_regionkey
)
SELECT 
    report
FROM 
    FinalReport
WHERE 
    comment_length > 50
ORDER BY 
    p_partkey;
