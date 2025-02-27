WITH string_aggregates AS (
    SELECT
        p_brand,
        COUNT(DISTINCT p_partkey) AS distinct_parts,
        STRING_AGG(p_name, ', ') AS part_names,
        AVG(p_retailprice) AS avg_price
    FROM part
    WHERE p_size > 10
    GROUP BY p_brand
),
region_summary AS (
    SELECT
        r_name,
        COUNT(DISTINCT n_nationkey) AS nations_count,
        STRING_AGG(n_name, '; ') AS nations
    FROM region
    JOIN nation ON r_regionkey = n_regionkey
    GROUP BY r_name
)
SELECT
    r.r_name AS region_name,
    r.nations_count,
    r.nations,
    s.s_name AS supplier_name,
    s.s_acctbal AS supplier_balance,
    sa.part_names,
    sa.avg_price
FROM region_summary r
JOIN supplier s ON s.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = r.r_name))
LEFT JOIN string_aggregates sa ON s.s_name LIKE '%' || ANY(string_to_array(sa.part_names, ', ')) || '%'
WHERE s.s_acctbal > 5000
ORDER BY r.r_name, s.s_name;
