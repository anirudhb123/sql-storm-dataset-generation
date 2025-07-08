
WITH RankedSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_nationkey,
        LENGTH(s_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY LENGTH(s_comment) DESC) AS rank
    FROM supplier
), CombinedData AS (
    SELECT 
        s.s_name,
        n.n_name AS nation_name,
        LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        MAX(r.r_name) AS region_name
    FROM RankedSuppliers s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.rank <= 5
    GROUP BY s.s_name, n.n_name
)
SELECT 
    cd.nation_name,
    cd.region_name,
    COUNT(cd.part_names) AS unique_part_count,
    SUM(cd.total_supply_value) AS total_supply_value
FROM CombinedData cd
GROUP BY cd.nation_name, cd.region_name
HAVING COUNT(cd.part_names) > 1
ORDER BY total_supply_value DESC;
