
WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        CONCAT('Part Name: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type, ', Size: ', p.p_size) AS part_info,
        REPLACE(UPPER(p.p_comment), ' ', '-') AS processed_comment,
        s.s_name AS supplier_name,
        SUBSTR(s.s_address, 1, 20) AS short_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_size > 10
),
AggregatedResults AS (
    SELECT 
        part_info,
        COUNT(*) AS supplier_count,
        STRING_AGG(DISTINCT nation_name, ', ') AS nations_supplied,
        STRING_AGG(DISTINCT supplier_name, ', ') AS unique_suppliers,
        AVG(ps_supplycost) AS avg_supply_cost
    FROM StringProcessing
    GROUP BY part_info
)
SELECT 
    part_info,
    supplier_count,
    nations_supplied,
    unique_suppliers,
    avg_supply_cost
FROM AggregatedResults
ORDER BY supplier_count DESC, avg_supply_cost ASC
LIMIT 10;
