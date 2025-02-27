WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COUNT(ps.ps_partkey) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
FilteredSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.nation_name,
        r.part_count,
        r.total_supply_cost
    FROM 
        RankedSuppliers r
    WHERE 
        r.rnk <= 3
)
SELECT 
    f.s_name,
    f.nation_name,
    f.part_count,
    f.total_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    FilteredSuppliers f
JOIN 
    partsupp ps ON f.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    f.s_suppkey, f.s_name, f.nation_name, f.part_count, f.total_supply_cost
ORDER BY 
    f.total_supply_cost DESC;
