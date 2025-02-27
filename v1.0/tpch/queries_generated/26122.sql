WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_in_region
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
)
SELECT 
    r.r_name AS region_name,
    rs.s_name AS supplier_name,
    rs.supplied_parts,
    rs.total_supply_cost
FROM RankedSuppliers rs
JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE rs.nation_name = n.n_name LIMIT 1)
WHERE rs.rank_in_region <= 3
ORDER BY r.r_name, rs.total_supply_cost DESC;
