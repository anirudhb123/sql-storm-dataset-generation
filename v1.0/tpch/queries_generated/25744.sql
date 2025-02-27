WITH StringAggregation AS (
    SELECT 
        p.p_name,
        REPLACE(UPPER(p.p_comment), 'ANY', '') AS trimmed_comment,
        CONCAT(CAST(p.p_partkey AS VARCHAR), '-', SUBSTRING(p.p_brand, 1, 5)) AS part_identifier,
        STRING_AGG(SUBSTRING(s.s_name, 1, 5), ', ') AS top_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE LENGTH(p.p_comment) > 20
    GROUP BY p.p_partkey, p.p_name, p.p_comment, p.p_brand
),
FinalBenchmark AS (
    SELECT 
        sa.part_identifier,
        sa.trimmed_comment,
        COUNT(sa.top_suppliers) AS supplier_count,
        AVG(p.p_retailprice) AS average_price
    FROM StringAggregation sa
    JOIN part p ON sa.part_identifier LIKE CONCAT('%', p.p_partkey, '%')
    GROUP BY sa.part_identifier, sa.trimmed_comment
)
SELECT 
    fb.part_identifier,
    fb.trimmed_comment,
    fb.supplier_count,
    fb.average_price
FROM FinalBenchmark fb
WHERE fb.average_price > (SELECT AVG(p.p_retailprice) FROM part p)
ORDER BY fb.supplier_count DESC, fb.average_price ASC;
