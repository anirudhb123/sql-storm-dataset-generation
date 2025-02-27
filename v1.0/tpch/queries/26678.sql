WITH StringAggregates AS (
    SELECT 
        p.p_brand,
        SUM(LENGTH(p.p_name)) AS total_name_length,
        COUNT(DISTINCT s.s_name) AS unique_suppliers,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        AVG(LENGTH(ps.ps_comment)) AS avg_partsupp_comment_length
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_brand
),
FinalResult AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        sa.*
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN StringAggregates sa ON sa.unique_suppliers > 5
)
SELECT 
    region_name,
    nation_name,
    p_brand,
    total_name_length,
    unique_suppliers,
    supplier_names,
    avg_partsupp_comment_length
FROM FinalResult
WHERE total_name_length > 200;
