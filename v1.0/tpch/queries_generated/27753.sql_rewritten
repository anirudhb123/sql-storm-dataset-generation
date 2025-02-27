WITH StringAnalysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type) AS composite_description,
        LENGTH(p.p_comment) AS comment_length,
        SUBSTR(p.p_comment, 1, 10) AS short_comment,
        CASE 
            WHEN LENGTH(p.p_name) > 30 THEN 'Long Name'
            ELSE 'Short Name'
        END AS name_length_category
    FROM part p
    WHERE p.p_size > 10
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey
),
FinalResult AS (
    SELECT 
        sa.p_partkey,
        sa.composite_description,
        sa.comment_length,
        rs.nation_count,
        rs.nations,
        rs.avg_supplier_balance,
        CONCAT('Comment Length: ', sa.comment_length, ', Regions: ', rs.nation_count) AS summary_info
    FROM StringAnalysis sa
    JOIN RegionSummary rs ON sa.p_partkey % 10 = rs.r_regionkey % 10  
)
SELECT 
    p_partkey,
    composite_description,
    comment_length,
    nation_count,
    nations,
    avg_supplier_balance,
    summary_info
FROM FinalResult
ORDER BY comment_length DESC, nation_count DESC;