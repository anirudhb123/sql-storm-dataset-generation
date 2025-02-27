WITH StringAggregates AS (
    SELECT 
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        CONCAT_WS(' ', p.p_mfgr, p.p_brand) AS mfgr_brand,
        LENGTH(p.p_comment) AS comment_length,
        COUNT(s.s_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand
),
RegionNations AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        CONCAT(n.n_name, ' - ', r.r_name) AS nation_region
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    a.p_name,
    a.mfgr_brand,
    a.comment_length,
    a.supplier_count,
    a.supplier_names,
    b.nation_region
FROM StringAggregates a
JOIN RegionNations b ON LENGTH(a.p_name) % 2 = 0
WHERE a.comment_length > 20
ORDER BY a.comment_length DESC, a.supplier_count DESC;
