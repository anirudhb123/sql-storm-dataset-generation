WITH StringOperations AS (
    SELECT 
        p.p_partkey,
        INITCAP(p.p_name) AS formatted_name,
        REPLACE(p.p_comment, 'old', 'new') AS updated_comment,
        SUBSTR(p.p_type, 1, 10) AS type_short,
        LENGTH(p.p_container) AS container_length,
        CONCAT('Part:', CAST(p.p_partkey AS VARCHAR), ' - ', p.p_name) AS part_description
    FROM part p
),
AggregatedData AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    s.s_name,
    c.c_name,
    r.r_name,
    so.formatted_name,
    so.updated_comment,
    so.type_short,
    so.container_length,
    so.part_description,
    ad.total_avail_qty,
    ad.avg_supply_cost
FROM StringOperations so
JOIN AggregatedData ad ON so.p_partkey = ad.ps_partkey
JOIN supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = so.p_partkey LIMIT 1)
JOIN customer c ON c.c_nationkey = s.s_nationkey
JOIN nation n ON n.n_nationkey = c.c_nationkey
JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE LENGTH(so.updated_comment) > 10
ORDER BY ad.total_avail_qty DESC, s.s_name;
