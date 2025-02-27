WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' (', p.p_brand, ') - ', LEFT(p.p_comment, 20), '...') AS part_description,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(CASE WHEN LENGTH(p.p_comment) > 10 THEN 1 ELSE 0 END) AS long_comments
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_comment
),
RegionNationStats AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        AVG(c.c_acctbal) AS average_account_balance,
        STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS market_segments
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON s.s_suppkey = c.c_nationkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    sa.part_description,
    rs.region_name,
    rs.nation_name,
    rs.average_account_balance,
    sa.supplier_count,
    sa.long_comments
FROM 
    StringAggregation sa
JOIN 
    RegionNationStats rs ON random() < 0.5  
ORDER BY 
    sa.supplier_count DESC, rs.average_account_balance DESC
LIMIT 100;